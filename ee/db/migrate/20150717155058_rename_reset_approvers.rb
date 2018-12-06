class RenameResetApprovers < ActiveRecord::Migration[4.2]
  def change
    rename_column :projects, :reset_approvers_on_push, :reset_approvals_on_push
  end
end
