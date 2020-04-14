# frozen_string_literal: true

class FillFileStoreLfsObjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute('UPDATE lfs_objects SET file_store = 1 WHERE file_store IS NULL')
  end

  def down
    # no-op
  end
end
