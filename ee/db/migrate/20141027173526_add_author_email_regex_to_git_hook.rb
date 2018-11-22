class AddAuthorEmailRegexToGitHook < ActiveRecord::Migration[4.2]
  def change
    add_column :git_hooks, :author_email_regex, :string
  end
end
