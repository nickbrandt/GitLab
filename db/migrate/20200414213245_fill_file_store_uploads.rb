# frozen_string_literal: true

class FillFileStoreUploads < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute('UPDATE uploads SET store = 1 WHERE store IS NULL')
  end

  def down
    # no-op
  end
end
