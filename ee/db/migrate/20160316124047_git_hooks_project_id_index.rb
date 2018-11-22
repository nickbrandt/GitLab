# rubocop:disable all
class GitHooksProjectIdIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    args = [:git_hooks, :project_id]

    if Gitlab::Database.postgresql?
      args << { algorithm: :concurrently }
    end

    add_index(*args)
  end
end
