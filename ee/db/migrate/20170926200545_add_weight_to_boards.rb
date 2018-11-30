class AddWeightToBoards < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :boards, :weight, :integer, index: true
  end
end
