class ChangeMaxFileSizeToNotNullOnGitHooks < ActiveRecord::Migration[4.2]
  def change
    change_column_null :git_hooks, :max_file_size, false, 0
  end
end
