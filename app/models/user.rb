class User < ApplicationRecord
  # Hiérarchie : admin (global) > responsable (par service) > collaborateur.
  ROLES = %w[collaborateur responsable admin].freeze

  NOTIFICATION_CHANNELS = %w[slack discord telegram].freeze
  NOTIFICATION_PERIODS = %w[office always slots].freeze

  THEMES = %w[default dark sunset forest unova].freeze

  has_secure_password
  has_many :slots
  belongs_to :service, optional: true
  after_create :fetch_slack_uid

  generates_token_for :invitation, expires_in: 7.days do
    password_digest&.first(10)
  end

  TELEGRAM_LINK_TTL = 15.minutes

  def self.create_telegram_link_token(user)
    token = SecureRandom.urlsafe_base64(16) 
    Rails.cache.write("telegram_link:#{token}", user.id, expires_in: TELEGRAM_LINK_TTL)
    token
  end

  def self.find_by_telegram_link_token(token)
    return nil if token.blank?
    user_id = Rails.cache.read("telegram_link:#{token}")
    return nil unless user_id
    Rails.cache.delete("telegram_link:#{token}") # one-shot
    find_by(id: user_id)
  end

  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  validates :theme, inclusion: { in: THEMES }
  validate  :notification_channels_must_be_valid
  validate  :notification_periods_must_be_valid

  scope :admin,         -> { where(role: "admin") }
  scope :responsable,   -> { where(role: "responsable") }
  scope :collaborateur, -> { where(role: "collaborateur") }
  scope :active,        -> { where("active IS DISTINCT FROM FALSE") }
  scope :always_on_call, -> { where("notification_periods @> ARRAY[?]::varchar[]", "always") }
  scope :call_on_office, -> {
    now = Time.current
    if now.hour >= 7 && now.hour < 18
      where("notification_periods @> ARRAY[?]::varchar[]", "office")
    else
      none
    end
  }

  # Alertes système : collaborateurs en astreinte + admins actifs.
  def self.alert_recipients
    on_call_ids = Slot.in_progress.where.not(user_id: nil).distinct.pluck(:user_id)
    active.where(id: on_call_ids + admin.pluck(:id) + always_on_call.pluck(:id) + call_on_office.pluck(:id))
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end

  def responsable?
    role == "responsable"
  end

  def collaborateur?
    role == "collaborateur"
  end

  def wants_slack?    = notification_channels.to_a.include?("slack")
  def wants_discord?  = notification_channels.to_a.include?("discord")
  def wants_telegram? = notification_channels.to_a.include?("telegram")

  # Libellé humain du rôle pour l'UI.
  def role_label
    case role
    when "admin"        then "Administrateur"
    when "responsable"  then "Responsable"
    when "collaborateur" then "Collaborateur"
    else "Utilisateur"
    end
  end

  # Alias conservé pour les vues existantes.
  def global_manager?
    admin?
  end

  def manager?
    admin? || responsable?
  end

  def manages_service?(target_service)
    return false if target_service.nil?
    admin? || (responsable? && service_id == target_service.id)
  end

  def manageable_users
    return User.all if admin?
    return User.where(service_id: service_id) if responsable? && service_id
    User.none
  end

  def manageable_slots
    return Slot.all if admin?
    return Slot.where(service_id: service_id) if responsable? && service_id
    Slot.none
  end

  def active?
    active != false
  end

  def fetch_slack_uid
    SlackUidSyncJob.perform_later(id)
  end

  private

  def notification_channels_must_be_valid
    invalid = notification_channels.to_a - NOTIFICATION_CHANNELS
    errors.add(:notification_channels, "contient un canal invalide : #{invalid.join(', ')}") if invalid.any?
  end

  def notification_periods_must_be_valid
    invalid = notification_periods.to_a - NOTIFICATION_PERIODS
    errors.add(:notification_periods, "contient une période invalide : #{invalid.join(', ')}") if invalid.any?
  end
end
