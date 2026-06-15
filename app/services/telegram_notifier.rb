# app/services/telegram_notifier.rb
#
# ENV requis :
#   TELEGRAM_BOT_TOKEN : token du bot (obtenu auprès de @BotFather)
#
# L'utilisateur DOIT avoir démarré une conversation avec le bot (/start) au
# moins une fois pour qu'on dispose d'un chat_id et qu'on puisse lui écrire.
class TelegramNotifier
  def self.send_message(chat_id:, message:)
    return if chat_id.blank?

    response = HTTParty.post(
      "https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendMessage",
      headers: { "Content-Type" => "application/json" },
      body: {
        chat_id: chat_id,
        text:    message,
        parse_mode: "HTML"
      }.to_json
    )
    Rails.logger.info("[TelegramNotifier] sendMessage status=#{response.code} body=#{response.parsed_response}")
    response.parsed_response
  end
end
