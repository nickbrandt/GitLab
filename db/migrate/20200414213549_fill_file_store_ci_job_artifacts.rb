# frozen_string_literal: true

class FillFileStoreCiJobArtifacts < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute('UPDATE ci_job_artifacts SET file_store = 1 WHERE file_store IS NULL')
  end

  def down
    # no-op
  end
end
