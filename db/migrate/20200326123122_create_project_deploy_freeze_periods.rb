# frozen_string_literal: true

class CreateProjectDeployFreezePeriods < ActiveRecord::Migration[6.0]
  def change
    create_table :project_deploy_freeze_periods do |t|
      t.references :project, foreign_key: true
      t.string :freeze_start
      t.string :freeze_end
      t.string :timezone

      t.timestamps
    end
  end
end
