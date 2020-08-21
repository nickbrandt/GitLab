# frozen_string_literal: true

class AddSeverityStatsIntoSecurityScansTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table(:security_scans) do |t|
      t.jsonb :severity_stats, null: false, default: {}
    end
  end
end
