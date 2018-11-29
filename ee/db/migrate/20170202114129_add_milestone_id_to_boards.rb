class AddMilestoneIdToBoards < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :boards, :milestone_id, :integer, null: true
  end
end
