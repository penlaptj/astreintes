class ConvertNotificationChannelToArray < ActiveRecord::Migration[8.1]
  # Passe d'un canal unique à plusieurs canaux simultanés (array Postgres).
  def up
    add_column :users, :notification_channels, :string,
               array: true, default: ["slack"], null: false

    # Copie la valeur existante (sauf "none" : on retombe sur la valeur par défaut ["slack"]).
    execute <<~SQL
      UPDATE users
      SET notification_channels = ARRAY[notification_channel]
      WHERE notification_channel IS NOT NULL
        AND notification_channel <> 'none'
    SQL

    remove_column :users, :notification_channel
  end

  def down
    add_column :users, :notification_channel, :string, default: "slack", null: false
    execute "UPDATE users SET notification_channel = COALESCE(notification_channels[1], 'slack')"
    remove_column :users, :notification_channels
  end
end
