# app/jobs/slack_uid_sync_job.rb
class SlackUidSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return if user.slack_uid.present?

    response = HTTParty.get(
      "https://slack.com/api/users.lookupByEmail?email=#{user.email}",
      headers: { "Authorization" => "Bearer #{ENV['SLACK_BOT_TOKEN']}" }
    )
    slack_uid = response.parsed_response.dig("user", "id")
    user.update(slack_uid: slack_uid) if slack_uid
  end
end