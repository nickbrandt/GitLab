# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSecurityReportArtifactPlanLimit < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, "ci_max_artifact_size_security", :integer, default: 0, null: false
  end
end
