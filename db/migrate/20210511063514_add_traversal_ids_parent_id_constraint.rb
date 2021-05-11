# frozen_string_literal: true

class AddTraversalIdsParentIdConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::SchemaHelpers

  DOWNTIME = false
  FUNCTION_NAME = 'validate_traversal_ids'
  TRIGGER_ON_INSERT_NAME = 'trigger_validate_traversal_ids_on_insert'
  TRIGGER_ON_UPDATE_NAME = 'trigger_validate_traversal_ids_on_update'

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        IF array_length(NEW.traversal_ids, 1) > 0 AND
           NEW.id <> COALESCE(NEW.traversal_ids[array_length(NEW.traversal_ids, 1)], 0)
        THEN
          RAISE EXCEPTION 'The id (%) must be the last element in traversal_ids %', NEW.id, NEW.traversal_ids;
        END IF;

        IF array_length(NEW.traversal_ids, 1) > 0 AND
           NEW.parent_id IS NULL AND
           NEW.traversal_ids <> ARRAY[NEW.id]
        THEN
          RAISE EXCEPTION 'The traversal_ids % must be [%] when parent_id is null', NEW.traversal_ids, NEW.id;
        END IF;

        IF array_length(NEW.traversal_ids, 1) > 0 AND
           NEW.parent_id IS NOT NULL AND
           NEW.parent_id <> COALESCE(NEW.traversal_ids[array_length(NEW.traversal_ids, 1)-1], 0)
        THEN
          RAISE EXCEPTION 'The parent_id (%) must be the second last element in traversal_ids %', NEW.parent_id, NEW.traversal_ids;
        END IF;

        RETURN NEW;
      SQL
    end

    execute(<<~SQL)
      CREATE CONSTRAINT TRIGGER #{TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON namespaces
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL

    execute(<<~SQL)
      CREATE CONSTRAINT TRIGGER #{TRIGGER_ON_UPDATE_NAME}
      AFTER UPDATE ON namespaces
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW
      WHEN (NEW.parent_id <> OLD.parent_id)
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:namespaces, TRIGGER_ON_INSERT_NAME)
    drop_trigger(:namespaces, TRIGGER_ON_UPDATE_NAME)
    drop_function(FUNCTION_NAME)
  end
end
