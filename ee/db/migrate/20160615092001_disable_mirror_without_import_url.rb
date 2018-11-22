# RemoveWrongImportUrlFromProjects migration missed setting the mirror flag to false when making import_url nil
# for invalid URIs that why we need this migration.

class DisableMirrorWithoutImportUrl < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def up
    execute("UPDATE projects SET mirror = false WHERE projects.mirror = true AND (projects.import_url IS NULL OR projects.import_url = '')")
  end
end
