# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixCiBuildsVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :ci_builds do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :description, :text
        t.change :name, :text
        t.change :ref, :text
        t.change :stage, :text
        t.change :status, :text
        t.change :target_url, :text
        t.change :type, :text
      end
    end
  end

  def down
    # no op
  end
end
