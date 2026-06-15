class AddNotificationChannelToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notification_channel, :string, default: "none", null: false
  end
end
