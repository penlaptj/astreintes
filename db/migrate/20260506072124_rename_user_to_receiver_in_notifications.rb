class RenameUserToReceiverInNotifications < ActiveRecord::Migration[8.1]
  def change
    rename_column :notifications, :user_id, :receiver_id
  end
end