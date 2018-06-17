#encoding: utf-8

#this class represent a contact imported by a csv file and waiting for valitation

require 'text'

class ImportContact < ActiveRecord::Base

  resourcify

  ##
  # Define the title fo the contact
  # Can be: M.|Mme
  #
  TITLES = ["M.", "Mme"]

  #take anomalies in constants
  NO_ANOMALY = Anomaly.find_by_name('ok')
  NO_COMPANY_ANOMALY = Anomaly.find_by_name('no_company')
  NAME_ANOMALY = Anomaly.find_by_name('name')
  DUPLICATE_IMPORT_ANOMALY = Anomaly.find_by_name('duplicate_import')
  DUPLICATE_DB_ANOMALY = Anomaly.find_by_name('duplicate_db')
  TITLE_ANOMALY = Anomaly.find_by_name('title')

  paginates_per 30

  belongs_to :account
  belongs_to :contact
  belongs_to :anomaly
  belongs_to :author_user, :foreign_key => 'created_by', :class_name => 'User'
  belongs_to :editor_user, :foreign_key => 'modified_by', :class_name => 'User'
  belongs_to :import

  # Help to sort by contacts in error
  #scope :anomaly, lambda { |a| where("anomaly IN (?)", a) unless a.blank? }
  scope :anomaly, lambda{|a| where('anomaly_id=?',a)}

  def author
    return author_user || User::default
  end

  def editor
    return editor_user || User::default
  end

  ##
  # Get the complete name of this person.
  #
  def full_name
    _forename='-'
    _surname='-'
    if !forename.blank?
      _forename=forename
    end
    if !surname.blank?
      _surname=surname
    end

    "#{_forename} #{UnicodeUtils.upcase(_surname, I18n.locale)}"
  end

  #
  # this metohd checked import_contact. If any invalid value, anomaly is set to type of anomaly
  # just one anomaly at a time. after each update import contact controller launch a new check
  # so, until anomaly doesn't exist, contact appear in red with a message in anomaly
  # column in index view
  #
  def check
    anomaly=NO_ANOMALY

    if self.account_id.blank?
      #anomaly level 2
      #search in DB if an account with company name like company name of the contact exist
      compte = Account.find_by_company(self.company.upcase) unless self.company.blank?
      if compte.nil?
          anomaly=NO_COMPANY_ANOMALY
      else
          self.update_attributes(:account_id=>compte.id)
      end
    end

    #anomaly level 3
    #if surname and forename are nil
    if self.surname.blank? && self.forename.blank?
      anomaly=NAME_ANOMALY
    end

    #if surname or forname is nil or invalid characters
    if (!self.surname.blank? && self.surname[/\w/]==nil) || (!self.forename.blank? && self.forename[/\w/]==nil)
      anomaly=NAME_ANOMALY

    #else search for duplicates (surname and forename equals)
    else
      #try to match with imported contacts except contact itself
      if self.no_search_duplicates==false
        ImportContact.find_each(:conditions => "id != #{self.id} AND no_search_duplicates=FALSE") do |contact2|
          if ImportContact.is_match(self, contact2)
            anomaly=DUPLICATE_IMPORT_ANOMALY
            if contact2.anomaly.name!='duplicate_import'
                contact2.update_attributes(:anomaly_id=>DUPLICATE_IMPORT_ANOMALY.id)
            end
          end
        end
      end

      #try to match with contacts
      if self.no_search_duplicates==false
        Contact.find_each do |contact2|
          if ImportContact.is_match(self, contact2)
            #anomaly=ImportAccount::ANOMALIES[:duplicate_in_db]+" : "+contact2.surname+"-"+contact2.forename
            anomaly=DUPLICATE_DB_ANOMALY
            self.update_attributes(:contact_id=>contact2.id)
          end
        end
      end

    end

    #if title is incorrect
    if self.title!="M." && self.title!="Mme"
      anomaly=TITLE_ANOMALY
    end

    self.update_attributes(:anomaly_id => anomaly.id)
  end

    #
    #this method match 2 contacts and return true if they seems duplicates
    #this is a class method because we need to match all import_contact when we destroy an
    #import_contact
    #
    def self.is_match (contact1,contact2)
        match=false
        #try to match phone and mobile in priority
        if !contact1.tel.blank? &&
            !contact2.tel.blank? &&
            !contact1.tel=~/\d/ &&
            !contact2.tel=~/\d/ &&
            contact1.tel.gsub(/[^0-9]/,"").eql?(contact2.tel.gsub(/[^0-9]/,""))
          match=true

        else
          if !contact1.mobile.blank? &&
              !contact2.mobile.blank? &&
              !contact1.mobile=~/\d/ &&
              !contact2.mobile=~/\d/ &&
              contact1.mobile.gsub(/[^0-9]/,"").eql?(contact2.mobile.gsub(/[^0-9]/,""))
            match=true

          else #try to match surnamename and forename

            if !contact1.surname.blank? && !contact1.forename.blank? && !contact2.surname.blank? && !contact2.forename.blank?
              #use gem Text
              surname1=contact1.surname.upcase
              forename1=contact1.forename.upcase
              surname2=contact2.surname.upcase
              forename2=contact2.forename.upcase
              score=Text::WhiteSimilarity.new
              # if match is too large, up value from 0.7 to upper
              # if match is too strict, down value from 0.7 to down
              if score.similarity(surname1,surname2)>0.7 && score.similarity(forename1,forename2)>0.7
                  match=true
              end
            end
          end
        end
        return match
    end
end
