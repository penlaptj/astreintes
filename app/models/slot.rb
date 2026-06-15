class Slot < ApplicationRecord
  STATES = %w[available pending assigned].freeze

  belongs_to :user, optional: true
  belongs_to :service, optional: true
  belongs_to :requested_by, class_name: "User", optional: true

  validates :starts_at, presence: true
  validates :assignment_state, inclusion: { in: STATES }

  scope :available, -> { where(assignment_state: "available") }
  scope :pending,   -> { where(assignment_state: "pending") }
  scope :assigned,  -> { where(assignment_state: "assigned") }
  scope :upcoming, -> { where("starts_at > ?", Time.now) }
  scope :passed, -> { where("ends_at < ?", Time.now) }
  scope :in_progress, -> { where("starts_at <= :now AND ends_at >= :now", now:Time.current)}
  scope :by_date, -> { order(:starts_at) }
  scope :by_duration, -> {
    order(Arel.sql("ends_at - starts_at"))
  }
  scope :by_compensation, -> {
    order(Arel.sql("COALESCE(compensation_money, 0), COALESCE(compensation_days, 0)"))
  }
  scope :euro_compensation, -> { where("compensation_money > 0") }
  scope :day_compensation, -> { where("compensation_days > 0") }

  def available?
    assignment_state == "available"
  end

  def pending?
    assignment_state == "pending"
  end

  def assigned?
    assignment_state == "assigned"
  end

  def duration_hours
    ((ends_at - starts_at) / 3600).round(1)
  end

  def compensation_label
    parts = []
    parts << "#{format_compensation(compensation_money)} €"     if compensation_money.to_f > 0
    parts << "#{format_compensation(compensation_days)} Jours"  if compensation_days.to_f > 0
    parts.empty? ? "—" : parts.join(" + ")
  end

  def status
    if ends_at < Time.now
      "terminé"
    elsif starts_at < Time.now
      "en cours"
    else
      "à venir"
    end
  end

  private

  def format_compensation(value)
    v = value.to_f
    v == v.to_i ? v.to_i : v
  end
end