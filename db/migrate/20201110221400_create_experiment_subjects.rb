# frozen_string_literal: true

class CreateExperimentSubjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    create_table :experiment_subjects do |t|
      t.references :experiment, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.integer :variant, limit: 2, null: false, default: 0
      t.timestamps_with_timezone null: false
    end

    add_reference :experiment_subjects, :user, index: true, foreign_key: { on_delete: :cascade }
    add_reference :experiment_subjects, :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }
    add_reference :experiment_subjects, :project, index: true, foreign_key: { on_delete: :cascade }

    # Require at least one of user_id, group_id, or project_id to be NOT NULL
    execute <<-SQL
      ALTER TABLE experiment_subjects ADD CONSTRAINT chk_at_least_one_subject CHECK (NOT ROW(user_id, group_id, project_id) IS NULL);
    SQL
  end

  def down
    drop_table :experiment_subjects
  end
end
