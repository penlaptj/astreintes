class AddAssignmentStateToSlots < ActiveRecord::Migration[8.1]
  def up
    add_column :slots, :assignment_state, :string, null: false, default: "available"
    add_reference :slots, :requested_by, foreign_key: { to_table: :users }

    # Les créneaux déjà affectés deviennent "assigned".
    execute "UPDATE slots SET assignment_state = 'assigned' WHERE user_id IS NOT NULL"
  end

  def down
    remove_reference :slots, :requested_by, foreign_key: { to_table: :users }
    remove_column :slots, :assignment_state
  end
end
