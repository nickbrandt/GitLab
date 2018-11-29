class AddPipelineQuotasToPlan < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :plans, :active_pipelines_limit, :integer
    add_column :plans, :pipeline_size_limit, :integer
  end
end
