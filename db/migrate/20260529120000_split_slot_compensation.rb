class SplitSlotCompensation < ActiveRecord::Migration[8.1]
  def up
    add_column :slots, :compensation_money, :decimal, precision: 10, scale: 2
    add_column :slots, :compensation_days,  :decimal, precision: 5,  scale: 1

    # Backfill depuis l'ancien schéma : un créneau n'avait qu'un seul type.
    execute <<~SQL.squish
      UPDATE slots SET compensation_money = compensation WHERE compensation_type = 'euro'
    SQL
    execute <<~SQL.squish
      UPDATE slots SET compensation_days = compensation WHERE compensation_type = 'jours'
    SQL

    remove_column :slots, :compensation
    remove_column :slots, :compensation_type
  end

  def down
    add_column :slots, :compensation, :decimal
    add_column :slots, :compensation_type, :string

    # Retour à un seul type : l'argent prime, sinon les jours (les créneaux
    # ayant les deux compensations perdent la récupération).
    execute <<~SQL.squish
      UPDATE slots
      SET compensation = compensation_money, compensation_type = 'euro'
      WHERE COALESCE(compensation_money, 0) > 0
    SQL
    execute <<~SQL.squish
      UPDATE slots
      SET compensation = compensation_days, compensation_type = 'jours'
      WHERE COALESCE(compensation_money, 0) = 0 AND COALESCE(compensation_days, 0) > 0
    SQL

    remove_column :slots, :compensation_money
    remove_column :slots, :compensation_days
  end
end
