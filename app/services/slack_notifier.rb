# app/services/slack_notifier.rb
class SlackNotifier
  TOKEN = ENV["SLACK_BOT_TOKEN"]

  def self.send_dm(slack_uid:, message:)
    # 1. Ouvrir le DM
    channel = open_dm(slack_uid)
    return unless channel

    # 2. Envoyer le message
    post_message(channel, message)
  end

  def self.open_dm(slack_uid)
    response = HTTParty.post(
      "https://slack.com/api/conversations.open",
      headers: { "Authorization" => "Bearer #{TOKEN}", "Content-Type" => "application/json" },
      body: { users: slack_uid }.to_json
    )
    Rails.logger.info("[SlackNotifier] open_dm response=#{response.parsed_response}")
    response.parsed_response.dig("channel", "id")
  end

  def self.post_message(channel, message)
    HTTParty.post(
      "https://slack.com/api/chat.postMessage",
      headers: { "Authorization" => "Bearer #{TOKEN}", "Content-Type" => "application/json" },
      body: { channel: channel, text: message }.to_json
    )
  end
end