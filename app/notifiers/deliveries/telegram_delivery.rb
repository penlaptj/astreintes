module Deliveries
  class TelegramDelivery < Noticed::DeliveryMethod
    def deliver
      user = recipient
      Rails.logger.info("[TelegramDelivery] user=#{user.first_name} chat_id=#{user.telegram_chat_id} message=#{notification.message}")
      return unless user.telegram_chat_id.present?

      result = TelegramNotifier.send_message(
        chat_id: user.telegram_chat_id,
        message: notification.message
      )
      Rails.logger.info("[TelegramDelivery] Telegram response=#{result}")
    end
  end
end
