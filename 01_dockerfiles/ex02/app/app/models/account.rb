# encoding: utf-8

##
# This class represents a Business. It's defined by a name, adress, ZIP code,
# City, Country, Phone number, Fax number, email adress, website, accounting code.
# This is linked to an Origin
# The type is an enumerable (Customer, Prospect, ...)
# This business cas have many Contact, Event, Task, Document or Relation.
# Also, it belongs to one User and one Origin
#



class Account < ActiveRecord::Base
  extend ToCsv
  resourcify

  validates :company, presence: true

  before_save :uppercase_company

  #has_one is added because import_account has an account_id column to store id of duplicate account
  has_many :import_account

  has_many :import_contacts

  has_many :contacts, :dependent => :destroy
  has_many :opportunities, :dependent => :destroy
  has_many :quotations, :dependent => :destroy
  has_many :events, :dependent => :destroy
  has_many :tasks, :dependent => :destroy
  has_many :documents, :dependent => :destroy
  #has_many :tags
  has_many :contracts, :dependent => :destroy

  has_and_belongs_to_many :tags
  belongs_to :user
  belongs_to :author_user, :foreign_key => 'created_by', :class_name => 'User'
  belongs_to :editor_user, :foreign_key => 'modified_by', :class_name => 'User'
  belongs_to :origin
  belongs_to :import
  belongs_to :activity
  belongs_to :payment_term
  belongs_to :account_category

  accepts_nested_attributes_for :events
  accepts_nested_attributes_for :contacts

  ##
  # Returns the relations of the accout.
  #
  # As each relation references two accounts in two different attributes, we can't use
  # a has_many relationship here ; :by_acccount scope will search in both account1 and
  # account2 columns of relations table.

  def relations
    Relation.by_account(self)
  end

  def author
    return author_user || User::default
  end

  def editor
    return editor_user || User::default
  end

  paginates_per 10

  ##
  # NEW : "category" has been moved to its own table AccountCategory
  # TYPES represents the Account Type
  # It can have these values: Client|Suspect|Prospect|Fournisseur|Partenaire|Adherent|Autre
  #
  #CATEGORIES = ['Client', 'Suspect', 'Prospect', 'Fournisseur','Partenaire', 'Adhérent', 'Autre']
  validates_inclusion_of :account_category_id, :in => AccountCategory.pluck(:id)


  # Help to sort by criteria
  scope :by_company_like, lambda { |company| where("UPPER(company) LIKE UPPER(?)",  "%#{company}%") unless company.blank? }
  scope :by_contact_full_name_like, (lambda do |contact_complete_name|
    unless contact_complete_name.blank?
      joins(:contacts).
      where("(UPPER(contacts.surname || ' ' || contacts.forename)) LIKE UPPER(?) OR
             (UPPER(contacts.forename || ' ' || contacts.surname)) LIKE UPPER(?)",
            "%#{contact_complete_name}%",
            "%#{contact_complete_name}%"
           )
    end
  end)
  scope :by_contact_id, lambda {|contact| joins(:contacts).where('contacts.id = ?', contact.id) unless contact.nil?}
  scope :by_tel, lambda { |tel| where("tel LIKE ?", '%'+tel+'%') unless tel.blank? }
  scope :by_zip, lambda { |zip| where("zip LIKE ?", zip + '%') unless zip.blank? }
  scope :by_country, lambda { |country| where("country = ?", country) unless country.blank? }
  scope :by_tags, lambda { |tags| joins(:tags).where("tags.id IN (?)", tags) unless tags.blank? }
  scope :by_user, lambda { |user| where("user_id = ?", user) unless user.blank? }
  scope :by_account_category, lambda { |cat| where("account_category_id IN (?)", cat) unless cat.blank? }
  scope :by_origin, lambda { |origin| where("origin_id IN (?)", origin) unless origin.blank? }
  scope :by_ids, lambda { |id| where("id IN (?)", id) unless id.blank?}
  scope :active, lambda { where(active: true) }
  scope :inactive, lambda { where(active: false) }
  scope :none, lambda { where('1 = 0') }
  scope :by_import_id, lambda {|import| joins(:import).where('import_id = ?', import) unless import.nil?}
  scope :by_account_tag, lambda { |tags| joins(:tags).where("tags.id IN (?)", tags) unless tags.blank? }
  scope :by_activity, lambda { |activity| where("activity_id IN (?)", activity) unless activity.blank? }
  scope :duplicate_phone, lambda {|phone_number, account_id| where("((REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tel, ' ', ''), '.', ''), '-', ''), '/', ''), '+', '') LIKE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(?, ' ', ''), '.', ''), '-', ''), '/', ''), '+', '')) AND NOT(id = ?))", "%" + phone_number + "%", account_id)}

  ###
  # Set the business name to upper
  #
  def uppercase_company

    UnicodeUtils.upcase(self.company, I18n.locale)

  end

  def full_adress
	tmp = self.adress1
	if !tmp==nil? && !self.adress2.blank?
		tmp += ', ' + self.adress2
	end
	if !tmp==nil? && !self.zip.blank?
		tmp += ', ' + self.zip
	end
	if !tmp==nil? && !self.city.blank?
		tmp += ', ' + self.city
	end
	return tmp
  end


  def localization_adress
    return "#{self.adress1},#{self.zip} #{self.city}".gsub(' ', '+')
  end


  def merge(account_to_merge_id)
    Account.transaction do
      account_to_merge = Account.find(account_to_merge_id)

      self.contacts << account_to_merge.contacts

      self.events << account_to_merge.events

      self.tasks << account_to_merge.tasks

      self.opportunities << account_to_merge.opportunities


      account_to_merge.tags.each do |tag|
	self.tags << tag unless self.tags.find {|t| t.id == tag.id}
      end

      self.documents << account_to_merge.documents

      account_to_merge.relations.each do |relation|
	relation.update_attributes!(:account1_id => self.id) unless ((relation.account2_id == self.id) or (self.relations.find {|r| r.account2_id == relation.account2_id}))
      end


      self.quotations << account_to_merge.quotations

      self.contracts << account_to_merge.contracts

      # Refresh the record
      account_to_merge = Account.find(account_to_merge_id)
      # Delete the merge account
      account_to_merge.destroy
    end # end transaction
  end
  
  def self.to_csv
    account_columns = Array.new

    Account.column_names.each do |column_name|
      if !(Account.columns_hash[column_name].type == :text )
        account_columns << column_name
      end
    end
    
    CSV.generate do |csv|
      csv << (account_columns)
      all.each do |account|
        csv << account.attributes.values_at(*account_columns)
      end
    end
  end  

  def self.default_account_category_id
    @setting = Setting.first
    @setting.default_account_category_id
  end

end
