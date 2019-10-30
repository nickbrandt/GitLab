# frozen_string_literal: true

class MigrateLfsObjectsToSeparateRegistry < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    Geo::TrackingBase.transaction do
      execute('LOCK TABLE file_registry IN EXCLUSIVE MODE')

      execute <<~EOF
          INSERT INTO lfs_object_registry (created_at, retry_at, lfs_object_id, bytes, retry_count, missing_on_primary, success, sha256)
          SELECT created_at, retry_at, file_id, bytes, retry_count, missing_on_primary, success, sha256::bytea
          FROM file_registry WHERE file_type = 'lfs'
      EOF

      execute <<~EOF
          CREATE OR REPLACE FUNCTION replicate_lfs_object_registry()
          RETURNS trigger AS
          $BODY$
          BEGIN
              IF (TG_OP = 'UPDATE') THEN
                  UPDATE lfs_object_registry
                  SET (retry_at, bytes, retry_count, missing_on_primary, success, sha256) =
                      (NEW.retry_at, NEW.bytes, NEW.retry_count, NEW.missing_on_primary, NEW.success, NEW.sha256::bytea)
                  WHERE lfs_object_id = NEW.file_id;
              ELSEIF (TG_OP = 'INSERT') THEN
                  INSERT INTO lfs_object_registry (created_at, retry_at, lfs_object_id, bytes, retry_count, missing_on_primary, success, sha256)
                  VALUES (NEW.created_at, NEW.retry_at, NEW.file_id, NEW.bytes, NEW.retry_count, NEW.missing_on_primary, NEW.success, NEW.sha256::bytea);
          END IF;
          RETURN NEW;
          END;
          $BODY$
          LANGUAGE 'plpgsql'
          VOLATILE;
      EOF

      execute <<~EOF
          CREATE TRIGGER replicate_lfs_object_registry
          AFTER INSERT OR UPDATE ON file_registry
          FOR EACH ROW WHEN (NEW.file_type = 'lfs') EXECUTE PROCEDURE replicate_lfs_object_registry();
      EOF
    end
  end

  def down
    execute("DELETE FROM lfs_object_registry WHERE ID IN (SELECT file_id FROM file_registry WHERE file_type = 'lfs')")
    execute("DROP TRIGGER IF EXISTS replicate_lfs_object_registry ON file_registry")
    execute("DROP FUNCTION IF EXISTS replicate_lfs_object_registry()")
  end
end
