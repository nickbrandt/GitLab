# rubocop:disable all
class AddIsSampleToGitHooks < ActiveRecord::Migration[4.2]
  def change
    add_column :git_hooks, :is_sample, :boolean, default: false
  end
end
