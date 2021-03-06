# frozen_string_literal: true
class Registration < ActiveRecord::Base
  self.table_name = "Preregs"

  scope :pending, -> { where(accepted_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }

  belongs_to :competition, foreign_key: "competitionId"
  belongs_to :user
  has_many :registration_events

  accepts_nested_attributes_for :registration_events, allow_destroy: true

  validates :user, presence: true, on: [:create]

  validates_numericality_of :guests, greater_than_or_equal_to: 0

  validate :competition_must_use_wca_registration
  private def competition_must_use_wca_registration
    if !competition
      errors.add(:competition, "Competition not found")
    elsif !competition.use_wca_registration?
      errors.add(:competition, "Competition registration is closed")
    end
  end

  def pending?
    accepted_at.nil?
  end

  def accepted?
    !pending?
  end

  def events
    registration_events.map(&:event_object).sort_by(&:rank)
  end

  def name
    user ? user.name : read_attribute(:name)
  end

  attr_accessor :pos
  attr_accessor :tied_previous

  attr_writer :birthday
  def birthday
    if user
      user.dob
    else
      birthYear == 0 || birthMonth == 0 || birthDay == 0 ? nil : Date.new(birthYear, birthMonth, birthDay)
    end
  end

  def gender
    user ? user.gender : read_attribute(:gender)
  end

  def countryId
    if user
      country = Country.find_by_iso2(user.country_iso2)
      if country
        return country.id
      end
    end
    read_attribute(:countryId)
  end

  def email
    user ? user.email : read_attribute(:email)
  end

  def personId
    user ? user.wca_id : read_attribute(:personId)
  end
  alias_method :wca_id, :personId

  def person
    Person.find_by_wca_id(personId)
  end

  def world_rank(event, type)
    person ? person.world_rank(event, type) : nil
  end

  def best_solve(event, type)
    person ? person.best_solve(event, type) : SolveTime.new(event.id, type, 0)
  end

  def waiting_list_info
    pending_registrations = competition.registrations.pending.order(:created_at)
    index = pending_registrations.index(self)
    OpenStruct.new(index: index, length: pending_registrations.length)
  end

  validate :user_can_register_for_competition
  private def user_can_register_for_competition
    if user&.cannot_register_for_competition_reasons.present?
      errors.add(:user_id, "User must be able to register for competition")
    end
  end

  validate :must_register_for_gte_one_event
  private def must_register_for_gte_one_event
    if events.empty?
      errors.add(:registration_events, "must register for at least one event")
    end
  end

  before_validation :unpack_dates
  private def unpack_dates
    if @birthday.nil? && !birthday.blank?
      @birthday = birthday.strftime("%F")
    end
    if @birthday.blank?
      self.birthYear = self.birthMonth = self.birthDay = 0
    else
      if @birthday.is_a? Date
        self.birthYear = @birthday.year
        self.birthMonth = @birthday.month
        self.birthDay = @birthday.day
      else
        unless /\A\d{4}-\d{2}-\d{2}\z/.match(@birthday)
          errors.add(:birthday, "invalid")
          return
        end
        self.birthYear, self.birthMonth, self.birthDay = @birthday.split("-").map(&:to_i)
        unless Date.valid_date? self.birthYear, self.birthMonth, self.birthDay
          errors.add(:birthday, "invalid")
          return
        end
      end
    end
  end
end
