class AddUsersCountToPositions < ActiveRecord::Migration[8.1]
  def up
    add_column :positions, :users_count, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE positions
      SET users_count = (SELECT COUNT(*) FROM users WHERE users.position_id = positions.id)
    SQL
  end

  def down
    remove_column :positions, :users_count
  end
end
