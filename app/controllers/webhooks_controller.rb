# Endpoints publics utilisés par des systèmes externes.
#
# Variables d'environnement attendues :
#   GRAFANA_WEBHOOK_SECRET   : bearer token configuré dans Grafana → Contact point.
#   UPTIME_WEBHOOK_SECRET    : bearer token configuré dans Uptime Kuma → Notification.
#   TELEGRAM_WEBHOOK_SECRET  : secret_token passé à Telegram via setWebhook ; renvoyé
#                              dans le header "X-Telegram-Bot-Api-Secret-Token".
#   TELEGRAM_BOT_TOKEN       : token du bot (utilisé pour répondre aux commandes /start).
#   TELEGRAM_BOT_USERNAME    : username du bot (sans @) pour générer le lien t.me/...
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login

  def grafana
    unless authenticate_grafana
      Rails.logger.warn("[GrafanaWebhook] auth refusée from=#{request.remote_ip}")
      return head :forbidden
    end

    payload = JSON.parse(request.body.read)
    result  = GrafanaAlertNotifier.broadcast_from_payload(payload)

    Rails.logger.info(
      "[GrafanaWebhook] payload reçu " \
      "delivered=#{result[:delivered]} duplicates=#{result[:duplicates]} skipped=#{result[:skipped]}"
    )

    render json: result, status: :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("[GrafanaWebhook] JSON invalide: #{e.message}")
    head :bad_request
  end

  def uptime
    unless authenticate_uptime
      Rails.logger.warn("[UptimeWebhook] auth refusée from=#{request.remote_ip}")
      return head :forbidden
    end

    payload = JSON.parse(request.body.read)
    result  = UptimeAlertNotifier.broadcast_from_payload(payload)

    Rails.logger.info(
      "[UptimeWebhook] payload reçu " \
      "delivered=#{result[:delivered]} duplicates=#{result[:duplicates]} skipped=#{result[:skipped]}"
    )

    render json: result, status: :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("[UptimeWebhook] JSON invalide: #{e.message}")
    head :bad_request
  end

  # Réception des updates Telegram. Doit être déclaré dans BotFather via setWebhook,
  # avec le secret_token = ENV["TELEGRAM_WEBHOOK_SECRET"] que Telegram renvoie ensuite
  # dans le header "X-Telegram-Bot-Api-Secret-Token".
  def telegram
    unless authenticate_telegram
      Rails.logger.warn("[TelegramWebhook] auth refusée from=#{request.remote_ip}")
      return head :forbidden
    end

    payload = JSON.parse(request.body.read)
    message = payload["message"] || payload["edited_message"]
    return head :ok unless message

    chat_id = message.dig("chat", "id")
    text    = message["text"].to_s.strip
    return head :ok if chat_id.blank?

    # Commande /start <token> : on lie le chat_id au compte de l'user qui a généré le token.
    if text.start_with?("/start")
      token = text.delete_prefix("/start").strip
      user  = token.present? ? User.find_by_telegram_link_token(token) : nil

      if user
        user.update!(telegram_chat_id: chat_id.to_s)
        TelegramNotifier.send_message(
          chat_id: chat_id,
          message: "✅ Compte lié à <b>#{ERB::Util.html_escape(user.first_name)}</b>. Tu recevras tes alertes ici."
        )
      else
        TelegramNotifier.send_message(
          chat_id: chat_id,
          message: "❌ Lien invalide ou expiré. Retourne dans Préférences sur astreintes pour en générer un nouveau."
        )
      end
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.warn("[TelegramWebhook] JSON invalide: #{e.message}")
    head :bad_request
  end

  private

  def authenticate_grafana
    authenticate_bearer(ENV["GRAFANA_WEBHOOK_SECRET"].to_s)
  end

  def authenticate_uptime
    authenticate_bearer(ENV["UPTIME_WEBHOOK_SECRET"].to_s)
  end

  def authenticate_telegram
    expected = ENV["TELEGRAM_WEBHOOK_SECRET"].to_s
    return false if expected.blank?

    provided = request.headers["X-Telegram-Bot-Api-Secret-Token"].to_s
    return false if provided.blank?

    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end

  def authenticate_bearer(expected)
    return false if expected.blank?

    header = request.headers["Authorization"].to_s
    return false unless header.start_with?("Bearer ")

    provided = header.delete_prefix("Bearer ").strip
    return false if provided.blank?

    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end
end
