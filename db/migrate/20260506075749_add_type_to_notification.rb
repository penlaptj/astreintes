class AddTypeToNotification < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :notification_type, :string
  end
end
