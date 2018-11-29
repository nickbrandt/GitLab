# rubocop:disable Migration/UpdateColumnInBatches
# rubocop:disable Migration/UpdateLargeTable
class UpdateMirrorWhenEmptyImportUrlInProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def change
    update_column_in_batches(:projects, :mirror, false) do |table, query|
      query.where(table[:import_url].eq(nil).or(table[:import_url].eq('')))
    end
  end
end
