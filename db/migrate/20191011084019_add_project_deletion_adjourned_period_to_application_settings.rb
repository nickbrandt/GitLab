# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProjectDeletionAdjournedPeriodToApplicationSettings < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  DEFAULT_NUMBER_OF_DAYS_BEFORE_REMOVAL = 7

  def change
    add_column :application_settings, :deletion_adjourned_period, :integer, default: DEFAULT_NUMBER_OF_DAYS_BEFORE_REMOVAL, null: false
  end
end
