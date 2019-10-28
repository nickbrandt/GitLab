# frozen_string_literal: true

class DeleteLfsObjectsFromFileRegistry < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    execute("DELETE FROM file_registry WHERE file_type = 'lfs'")
    execute('DROP TRIGGER IF EXISTS replicate_lfs_object_registry ON file_registry')
    execute('DROP FUNCTION IF EXISTS replicate_lfs_object_registry()')
  end

  def down
    # no-op
  end
end
