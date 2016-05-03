class Announcement
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  AUDIENCE_KINDS = %W{Employer Employee IVL Broker GA}

  field :content, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :audiences, type: Array, default: []


  validates_presence_of :content, :start_date, :end_date
  validate :must_have_audiences
  validate :date_checks

  def must_have_audiences
    errors.add(:base, 'Please select at least one Audience') if audiences.blank?
  end

  def date_checks
    return if start_date.blank? || end_date.blank?
    errors.add(:base, "End Date should be later than today") if end_date < TimeKeeper.date_of_record
    errors.add(:base, "End Date should be later than Start date") if end_date < start_date
  end

  scope :current, ->{ where(:start_date.lte => TimeKeeper.date_of_record, :end_date.gte => TimeKeeper.date_of_record) }
  scope :by_audience, ->(value){ where(audiences: value) }

  def audiences_for_display
    audiences.join(',')
  end

  before_validation :update_audiences
  def update_audiences
    self.audiences = audiences.select {|audience| audience.present? } if audiences.present?
  end

  class << self
    AUDIENCE_KINDS.each do |kind|
      define_method "current_msg_for_#{kind.downcase}".to_sym do
        Announcement.current.by_audience(kind).map(&:content)
      end
    end
  end
end