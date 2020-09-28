# frozen_string_literal: true

class FixProjectsVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :projects do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :avatar, :text
        t.change :import_source, :text
        t.change :import_type, :text
        t.change :import_url, :text
        t.change :name, :text
        t.change :path, :text
      end
    end
  end

  def down
    # no op
  end
end
