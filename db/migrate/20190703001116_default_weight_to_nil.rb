# frozen_string_literal: true

class DefaultWeightToNil < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Board < ActiveRecord::Base
    self.table_name = 'boards'

    include ::EachBatch
  end

  def up
    Gitlab::BackgroundMigration.steal('UpdateBoardWeightsFromNoneToAny')

    Board.where(weight: -1).each_batch(of: 50) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      say "Setting board weights from None to Any: #{range[0]} - #{range[1]}"

      Gitlab::BackgroundMigration::UpdateBoardWeightsFromNoneToAny.new.perform(*range)
    end
  end

  def down
    # noop
  end
end
