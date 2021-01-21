# frozen_string_literal: true

class AddDevopsAdoptionGroupSegment < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :analytics_devops_adoption_segments, :namespace_id, :integer
      add_foreign_key :analytics_devops_adoption_segments, :namespaces
      add_index :analytics_devops_adoption_segments, :namespace_id, unique: true
    end
  end

  def down
    with_lock_retries do
      remove_column :analytics_devops_adoption_segments, :namespace_id
    end
  end
end
