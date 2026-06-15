module Deliveries
  class SlackDelivery < Noticed::DeliveryMethod
    def deliver
      user = recipient
      Rails.logger.info("[SlackDelivery] user=#{user.first_name} slack_uid=#{user.slack_uid} message=#{notification.message}")
      return unless user.slack_uid.present?

      result = SlackNotifier.send_dm(
        slack_uid: user.slack_uid,
        message:   notification.message
      )
      Rails.logger.info("[SlackDelivery] Slack response=#{result}")
    end
  end
end