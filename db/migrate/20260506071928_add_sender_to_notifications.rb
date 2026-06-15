class AddSenderToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :sender_id, :integer
    add_foreign_key :notifications, :users, column: :sender_id
  end
end
