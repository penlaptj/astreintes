class GrafanaAlertNotifier < Noticed::Event
  include AlertBroadcasting

  class Notification < Noticed::Notification
  end

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
      "grafana_alert"
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

    def severity
      event.params[:severity].to_s
    end

    def grafana_url
      event.params[:grafana_url]
    end

    def fingerprint
      event.params[:fingerprint]
    end

    def firing?
      %w[firing alerting].include?(state.downcase)
    end
  end

  # -------- Extraction du payload (interface AlertBroadcasting) --------

  def self.extract_alerts(payload)
    return payload["alerts"] if payload["alerts"].is_a?(Array) && payload["alerts"].any?

    [payload] # format legacy
  end
  private_class_method :extract_alerts

  def self.build_params(payload, alert)
    labels      = alert["labels"]      || {}
    annotations = alert["annotations"] || payload["commonAnnotations"] || {}

    {
      title:       annotations["summary"]     || labels["alertname"] || payload["title"]   || "Alerte Grafana",
      message:     annotations["description"] || alert["message"]    || payload["message"] || "",
      state:       alert["status"]            || payload["status"]   || payload["state"]   || "unknown",
      severity:    labels["severity"]         || "info",
      fingerprint: alert["fingerprint"]       || payload["groupKey"],
      grafana_url: alert["generatorURL"]      || payload["externalURL"],
      sender_id:   nil,
      sender_name: "Grafana"
    }
  end
  private_class_method :build_params
end
