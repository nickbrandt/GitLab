# frozen_string_literal: true

class AddEpicBoardPositions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      create_table :boards_epic_board_positions do |t|
        t.references :board, foreign_key: { on_delete: :cascade }, null: false, index: false
        t.references :epic, foreign_key: { on_delete: :cascade }, null: false, index: true
        t.integer :relative_position

        t.timestamps_with_timezone null: false

        t.index [:board_id, :epic_id], unique: true, name: :index_boards_epic_board_positions_on_board_id_and_epic_id
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :boards_epic_board_positions
    end
  end
end
