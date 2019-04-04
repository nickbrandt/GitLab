# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexesToSharedRunnersMinutesLimitAndExtraSharedRunnersMinutesLimitColumnsOnNamespaces < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_concurrent_index :namespaces, [:shared_runners_minutes_limit, :extra_shared_runners_minutes_limit], name: 'index_namespaces_on_shared_and_extra_runners_minutes_limit'
  end

  def down
    remove_concurrent_index :namespaces, [:shared_runners_minutes_limit, :extra_shared_runners_minutes_limit]
  end
end
