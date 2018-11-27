class AddNameToBoards < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :boards, :name, :string, default: 'Development'
  end

  def down
    remove_column :boards, :name
  end
end
