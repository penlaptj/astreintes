class AstreinteNotifier < Noticed::Event
  class Notification < Noticed::Notification
  end

  deliver_by :action_cable do |config|
    config.channel = "NotificationChannel"
    config.stream = -> { recipient }
    config.message = -> { params }
  end

  # Email et in-app sont toujours actifs (canaux par défaut).
  deliver_by :email do |config|
    config.mailer = "SlotMailer"
    config.method = :notify
  end

  # Canaux sociaux : envoyés uniquement si l'utilisateur les a cochés dans /preferences.
  deliver_by :slack,    class: "Deliveries::SlackDelivery",    if: -> { recipient.wants_slack? }
  deliver_by :discord,  class: "Deliveries::DiscordDelivery",  if: -> { recipient.wants_discord? }
  deliver_by :telegram, class: "Deliveries::TelegramDelivery", if: -> { recipient.wants_telegram? }

  notification_methods do
    def message
      case params[:notification_type]
      when "swap_request"
        "#{params[:sender_name]} vous demande un échange d'astreinte"
      when "astreinte_reminder"
        "Votre astreinte commence dans 1 heure"
      when "assigned", "slot_assigned"
        "Vous avez été assigné à une astreinte"
      when "urgent_call"
        "#{params[:sender_name]} vous convoque immédiatement pour votre astreinte"
      else
        "Nouvelle notification"
      end
    end

    def notification_type
      params[:notification_type]
    end
  end
end