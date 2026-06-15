class AddNotificationPeriodsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notification_periods, :string,
               array: true, default: ["slots"], null: false
  end
end