# rubocop:disable all
class AddMemberCheckToGitHooks < ActiveRecord::Migration[4.2]
  def change
    add_column :git_hooks, :member_check, :boolean, default: false, null: false
  end
end
