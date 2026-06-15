class CreateServicesAndAssociations < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.string :description

      t.timestamps
    end
    add_index :services, :name, unique: true

    add_reference :users, :service, foreign_key: true
    add_reference :slots, :service, foreign_key: true
  end
end
