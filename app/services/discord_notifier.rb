# app/services/discord_notifier.rb
#
# ENV requis :
#   DISCORD_BOT_TOKEN  : token du bot Discord (Discord Developer Portal → Application → Bot)
#
# Le bot doit partager au moins un serveur avec l'utilisateur ET l'utilisateur
# doit avoir activé les DMs depuis les membres du serveur, sinon l'envoi échoue
# silencieusement côté Discord (403).
class DiscordNotifier
  API_BASE = "https://discord.com/api/v10".freeze

  def self.send_dm(discord_user_id:, message:)
    return if discord_user_id.blank?

    channel_id = open_dm(discord_user_id)
    return unless channel_id

    post_message(channel_id, message)
  end

  def self.open_dm(discord_user_id)
    response = HTTParty.post(
      "#{API_BASE}/users/@me/channels",
      headers: auth_headers,
      body: { recipient_id: discord_user_id.to_s }.to_json
    )
    Rails.logger.info("[DiscordNotifier] open_dm status=#{response.code} response=#{response.parsed_response}")
    response.parsed_response.is_a?(Hash) ? response.parsed_response["id"] : nil
  end

  def self.post_message(channel_id, message)
    HTTParty.post(
      "#{API_BASE}/channels/#{channel_id}/messages",
      headers: auth_headers,
      body: { content: message }.to_json
    )
  end

  def self.auth_headers
    {
      "Authorization" => "Bot #{ENV['DISCORD_BOT_TOKEN']}",
      "Content-Type"  => "application/json"
    }
  end
  private_class_method :auth_headers
end
