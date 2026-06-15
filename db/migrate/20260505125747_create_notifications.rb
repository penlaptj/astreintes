class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :message
      t.boolean :read
      t.references :slot, null: false, foreign_key: true

      t.timestamps
    end
  end
end
