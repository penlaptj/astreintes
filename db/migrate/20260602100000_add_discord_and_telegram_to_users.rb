class AddDiscordAndTelegramToUsers < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:users, :discord_user_id)
      add_column :users, :discord_user_id, :string
    end

    unless column_exists?(:users, :telegram_chat_id)
      add_column :users, :telegram_chat_id, :string
    end
  end
end
