class AddSlackUidToUsers < ActiveRecord::Migration[8.1]
  def change
    # Idempotent : la colonne peut déjà exister si elle a été ajoutée
    # à la main avant que cette migration n'arrive en base.
    add_column :users, :slack_uid, :string unless column_exists?(:users, :slack_uid)
  end
end
