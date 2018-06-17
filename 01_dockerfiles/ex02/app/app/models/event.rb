# encoding: utf-8

##
# This class represents an event. The most of the time, this is an exchange
# between two contacts  of two differents Business.
# So, an Event is defined by a Contact, an Account, an EventType, a User and a Task
#
class Event < ActiveRecord::Base

  resourcify

  belongs_to :contact
  belongs_to :account
  belongs_to :event_type
  belongs_to :user
  belongs_to :author_user, :foreign_key => 'created_by', :class_name => 'User'
  belongs_to :editor_user, :foreign_key => 'modified_by', :class_name => 'User'
  belongs_to :task
  belongs_to :opportunity
  belongs_to :quotation

  paginates_per 10

  # Conservé pour le bon fonctionnement des migrations --> non utilisé
  has_attached_file :attach

  # Nouvelle gestion des pièces-jointes
  has_many :event_attachments, :dependent => :destroy
  accepts_nested_attributes_for :event_attachments
  alias_attribute :attachments, :event_attachments

  # Validation using global Settings
  # don't use validates_associated : it does not work ;)
  validates :account, :presence => true, if: :mandatory_account_setting?
  validates :contact, :presence => true, if: :mandatory_contact_setting?

  def mandatory_account_setting?
    @setting = Setting.all.first
    @setting.mandatory_account
  end

  def mandatory_contact_setting?
    @setting = Setting.all.first
    @setting.mandatory_contact
  end

  def default_event_type_id
    @setting = Setting.all.first
    @setting.default_event_type_id
  end

  def author
    return author_user || User::default
  end

  def editor
    return editor_user || User::default
  end

  scope :by_account_id, lambda { |account_id| where("events.account_id = ?", account_id) unless account_id.blank? }
  scope :by_event_type_id, lambda { |event_type_id| where("events.event_type_id = ?", event_type_id) unless event_type_id.blank? }
  scope :by_account_company_like, lambda { |account_company| joins(:account).where("UPPER(accounts.company) LIKE UPPER(?)", "%#{account_company}%") unless account_company.blank? }
  scope :by_contact_id, lambda { |contact_id| where("events.contact_id = ?", contact_id) unless contact_id.blank? }
  scope :by_user_id, lambda { |user_id| where("events.user_id = ?", user_id) unless user_id.blank? }
  scope :by_author_user_id, lambda { |author_user_id| where( "events.created_by = ?", author_user_id) unless author_user_id.blank? }
  scope :by_content_like, lambda { |content| where("UPPER(events.notes) LIKE UPPER(?) or UPPER(events.notes2) LIKE UPPER(?)", "%#{content}%", "%#{content}%") unless content.blank? }
  scope :between_dates, lambda { |start_at, end_at| where("events.created_at >= ? AND events.created_at <= ?", start_at, end_at) }
  scope :with_event_type, lambda { where("event_type_id is not null")}

  validate :validate_end_date_after_start_date

  def validate_end_date_after_start_date
    if date_end && date_begin
        errors.add(:date_end, "La date de fin doit être postérieure à la date de début!") if date_end < date_begin
    end
  end

end
