class RemoveInvalidApprovers < ActiveRecord::Migration[4.2]
  def up
    execute("DELETE FROM approvers WHERE user_id = 0")
  end

  def down
  end
end
