class CreateSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :slots do |t|
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :slot_type
      t.decimal :compensation
      t.string :description
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
  end
end
