class AddSharedRunnersMinutesLimitToNamespace < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :shared_runners_minutes_limit, :integer
  end
end
