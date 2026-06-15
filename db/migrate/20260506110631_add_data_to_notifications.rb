class AddDataToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :data, :jsonb
  end
end
