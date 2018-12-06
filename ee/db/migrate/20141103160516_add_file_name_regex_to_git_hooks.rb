class AddFileNameRegexToGitHooks < ActiveRecord::Migration[4.2]
  def change
    add_column :git_hooks, :file_name_regex, :string
  end
end
