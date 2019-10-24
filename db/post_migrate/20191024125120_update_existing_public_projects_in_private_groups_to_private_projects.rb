# frozen_string_literal: true

class UpdateExistingPublicProjectsInPrivateGroupsToPrivateProjects < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 100

  PRIVATE = 0
  INTERNAL = 10

  disable_ddl_transaction!

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'
  end

  class Project < ActiveRecord::Base
    include EachBatch

    belongs_to :namespace

    scope :with_group_visibility, ->(visibility) do
      joins(:namespace)
        .where(namespaces: { type: 'Group', visibility_level: visibility })
        .where('projects.visibility_level > namespaces.visibility_level')
    end

    self.table_name = 'projects'
  end

  def up
    # Update project's visibility to be the same as the group
    # if it is more restrictive than `PUBLIC`.
    update_projects_visibility(PRIVATE)
    update_projects_visibility(INTERNAL)
  end

  def down
    # no-op: unrecoverable data migration
  end

  private

  def update_projects_visibility(visibility)
    say_with_time("Updating project visibility to #{visibility}") do
      Project.with_group_visibility(visibility).select(:id).each_batch(of: BATCH_SIZE) do |batch, _index|
        batch_sql = batch.select(:id).to_sql

        say("Updating #{batch.size} items.", true)

        execute("UPDATE projects SET visibility_level = '#{visibility}' WHERE id IN (#{batch_sql})")
      end
    end
  end
end
