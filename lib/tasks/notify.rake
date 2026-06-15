namespace :slots do
  desc "Notifie les astreintes qui commencent dans 1 heure"
  task notify: :environment do
    now = Time.now.in_time_zone("Europe/Paris")
    target = now + 1.hour

    sender = User.find_by(role: "admin")
    Slot.where(starts_at: target.beginning_of_hour..target.end_of_hour).each do |slot|
        next unless slot.user
        

        receiver = slot.user
        notification = Notification.create!(
        receiver_id: receiver.id,
        sender_id: sender.id,
        slot_id: slot.id,
        # notification_type: "astreinte_reminder",
        notification_type: "accept_assign",
        read: false,
        data: {
            sender: {
              id: sender.id,
              name: sender.first_name
            },
            receiver: {
              id: receiver.id,
              name: receiver.first_name
            },
            slot: {
              id: slot.id,
              starts_at: slot.starts_at,
              ends_at: slot.ends_at,
              compensation: slot.compensation_label
            }
        }
        )

        NotificationChannel.broadcast_to(
          receiver,
          {
            id: notification.id,
            message: notification.message,
            type: notification.notification_type,
            sender: sender.full_name,
            created_at: notification.created_at.localtime.strftime("%d/%m/%Y %H:%M")
          }
        )

        SlotMailer.notify(slot).deliver_now

        puts "CRON FONCTIONNE"
    end
  end
end