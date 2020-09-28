# frozen_string_literal: true

class FixNamespacesVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :namespaces do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :avatar, :text
        t.change :description, :text, default: ''
        t.change :name, :text
        t.change :path, :text
        t.change :type, :text
      end
    end
  end

  def down
    # no op
  end
end
