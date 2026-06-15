module AlertBroadcasting
  extend ActiveSupport::Concern

  # Fenêtre de déduplication : on ignore une alerte au même fingerprint déjà
  # reçue dans cette fenêtre (les sondes spamment les alertes "firing").
  #DEDUP_WINDOW = 5.minutes
  DEDUP_WINDOW = 30.seconds
  class_methods do
    # Diffuse un payload brut. Retourne { delivered:, duplicates:, skipped: }.
    def broadcast_from_payload(payload)
      counts = { delivered: 0, duplicates: 0, skipped: 0 }

      extract_alerts(payload).each do |raw_alert|
        params = build_params(payload, raw_alert)

        if params[:title].blank? && params[:message].blank?
          counts[:skipped] += 1
          next
        end

        if params[:fingerprint].present? && recent_duplicate?(params[:fingerprint])
          counts[:duplicates] += 1
          next
        end

        deliver_to_recipients!(params)
        counts[:delivered] += 1
      end

      counts
    end

    def recent_duplicate?(fingerprint)
      Noticed::Event
        .where(type: name)
        .where("params->>'fingerprint' = ?", fingerprint)
        .where("created_at > ?", DEDUP_WINDOW.ago)
        .exists?
    end

    def deliver_to_recipients!(params)
      recipients = User.alert_recipients
      return if recipients.empty?

      with(**params).deliver(recipients)
    end
  end
end
