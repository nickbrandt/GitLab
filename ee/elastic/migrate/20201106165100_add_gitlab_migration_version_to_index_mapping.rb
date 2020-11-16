# frozen_string_literal: true

class AddGitlabMigrationVersionToIndexMapping < Elastic::Migration
  def migrate
    if completed?
      log 'Skipping adding gitlab_migration_version to index mapping migration since it is already applied'
      return
    end

    mapping = {
      'properties' => {
        'gitlab_migration_version' => {
          'type' => 'keyword'
        }
      }
    }

    log 'Adding gitlab_migration_version to index mapping'
    helper.add_mapping(mapping: mapping)
    log 'Adding gitlab_migration_version to index mapping is completed'
  end

  def completed?
    helper.get_properties.key?('gitlab_migration_version')
  end
end
