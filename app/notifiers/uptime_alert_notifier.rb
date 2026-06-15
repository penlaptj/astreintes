class UptimeAlertNotifier < Noticed::Event
  include AlertBroadcasting

  class Notification < Noticed::Notification
  end

  # Codes d'état Uptime Kuma.
  STATUS_LABELS = { 0 => "down", 1 => "up", 2 => "pending", 3 => "maintenance" }.freeze

  deliver_by :database

  deliver_by :action_cable do |config|
    config.channel = "NotificationChannel"
    config.stream  = -> { recipient }
    config.message = -> { params }
  end

  # Canaux sociaux : respectent les préférences de chaque destinataire.
  deliver_by :slack,    class: "Deliveries::SlackDelivery",    if: -> { recipient.wants_slack? }
  deliver_by :discord,  class: "Deliveries::DiscordDelivery",  if: -> { recipient.wants_discord? }
  deliver_by :telegram, class: "Deliveries::TelegramDelivery", if: -> { recipient.wants_telegram? }

  notification_methods do
    def notification_type
      "uptime_alert"
    end

    def title
      event.params[:title]
    end

    def message
      event.params[:message]
    end

    def state
      event.params[:state].to_s
    end

    def monitor_url
      event.params[:monitor_url]
    end

    def fingerprint
      event.params[:fingerprint]
    end

    def down?
      %w[down pending].include?(state.downcase)
    end

    def firing?
      down?
    end
  end

  # -------- Extraction du payload (interface AlertBroadcasting) --------

  # Uptime Kuma envoie un seul objet par requête ; on tolère aussi un tableau.
  def self.extract_alerts(payload)
    return payload["heartbeats"] if payload["heartbeats"].is_a?(Array) && payload["heartbeats"].any?

    [payload]
  end
  private_class_method :extract_alerts

  def self.build_params(_payload, alert)
    heartbeat = alert["heartbeat"] || {}
    monitor   = alert["monitor"]   || {}

    state = STATUS_LABELS.fetch(heartbeat["status"]) do
      (alert["status"] || heartbeat["status"] || "unknown").to_s.downcase
    end

    name = monitor["name"].presence || alert["name"].presence || "Service"
    down = state == "down"

    {
      title:       down ? "#{name} est indisponible" : "#{name} — #{state}",
      message:     heartbeat["msg"].presence || alert["message"].presence || alert["msg"].presence || "",
      state:       state,
      monitor_url: monitor["url"].presence || alert["url"].presence,
      fingerprint: ["uptime", monitor["id"] || name, state].join("-"),
      sender_id:   nil,
      sender_name: "Uptime"
    }
  end
  private_class_method :build_params
end
