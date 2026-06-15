module Deliveries
  class DiscordDelivery < Noticed::DeliveryMethod
    def deliver
      user = recipient
      Rails.logger.info("[DiscordDelivery] user=#{user.first_name} discord_user_id=#{user.discord_user_id} message=#{notification.message}")
      return unless user.discord_user_id.present?

      result = DiscordNotifier.send_dm(
        discord_user_id: user.discord_user_id,
        message:         notification.message
      )
      Rails.logger.info("[DiscordDelivery] Discord response=#{result}")
    end
  end
end
