class DefaultNotificationChannelToSlack < ActiveRecord::Migration[8.1]
  # Slack devient le canal social par défaut ; "none" est retiré.
  def up
    change_column_default :users, :notification_channel, from: "none", to: "slack"
    execute "UPDATE users SET notification_channel = 'slack' WHERE notification_channel = 'none'"
  end

  def down
    change_column_default :users, :notification_channel, from: "slack", to: "none"
  end
end
