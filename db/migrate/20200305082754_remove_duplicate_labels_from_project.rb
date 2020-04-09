# frozen_string_literal: true

class RemoveDuplicateLabelsFromProject < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  CREATE = 1
  RENAME = 2

  class BackupLabel < Label
    include BulkInsertSafe
    include EachBatch

    self.table_name = 'backup_labels'
  end

  class Label < ApplicationRecord
    self.table_name = 'labels'
  end

  class Project < ApplicationRecord
    include EachBatch

    self.table_name = 'projects'
  end

  DEDUPLICATE_BATCH_SIZE = 100_000
  RESTORE_BATCH_SIZE = 100

  def up
    # Split to smaller chunks
    # Loop rather than background job, every 100,000
    # there are 45,000,000 projects in total
    Project.each_batch(of: DEDUPLICATE_BATCH_SIZE) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      remove_full_duplicates(*range)
      rename_partial_duplicates(*range)
    end
  end

  def down
    # we could probably make this more efficient by getting them in bulk by restore action
    # and then applying them all at the same time...
    BackupLabel.each_batch(of: RESTORE_BATCH_SIZE) do |backup_label|
      action = backup_label.restore_action
      target = Label.find(backup_label.id)

      next unless target
      next unless action

      if action == RENAME
        if target.title == backup_label.new_title
          say "Restoring label title '#{target.title}' to backup value '#{backup_label.title}'"
          target.update_attribute(:title, backup_label.title)
        end
      elsif action == CREATE
        restored_label = Label.new(backup_label.attributes)
        say "Restoring label from deletion with backup attributes #{backup_label.attributes}"

        if restored_label.valid?
          restored_label.save
          backup_label.destroy
        end
      end
    end
  end

  def remove_full_duplicates(start_id, stop_id)
    # Fields that are considered duplicate:
    # project_id title template description type color

    duplicate_labels = ApplicationRecord.connection.execute(<<-SQL.squish)
WITH data AS (
  SELECT labels.*,
  row_number() OVER (PARTITION BY labels.project_id, labels.title, labels.template, labels.description, labels.type, labels.color ORDER BY labels.id) AS row_number,
  #{CREATE} AS restore_action
  FROM labels
  WHERE labels.project_id BETWEEN #{start_id} AND #{stop_id}
  AND NOT EXISTS (SELECT * FROM board_labels WHERE board_labels.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM label_links WHERE label_links.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM label_priorities WHERE label_priorities.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM lists WHERE lists.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM resource_label_events WHERE resource_label_events.label_id = labels.id)
) SELECT * FROM data WHERE row_number > 1;
    SQL

    if duplicate_labels.any?
      # create backup records
      BackupLabel.insert_all!(duplicate_labels.map { |label| label.except("row_number") })

      ApplicationRecord.connection.execute(<<-SQL.squish)
DELETE FROM labels
WHERE labels.id IN (#{duplicate_labels.map { |dup| dup["id"] }.join(", ")});
      SQL
    end
  end

  def rename_partial_duplicates(start_id, stop_id)
    soft_duplicates = ApplicationRecord.connection.execute(<<-SQL.squish)
WITH data AS (
  SELECT
     *,
     title || '_' || 'duplicate' || extract(epoch from now()) AS new_title,
     #{RENAME} AS restore_action,
     row_number() OVER (PARTITION BY project_id, title ORDER BY id) AS row_number
  FROM labels
  WHERE project_id BETWEEN #{start_id} AND #{stop_id}
) SELECT * from data where row_number > 1;
    SQL

    if soft_duplicates.any?
      # create backup records
      BackupLabel.insert_all!(soft_duplicates.map { |label| label.except("row_number") })

      ApplicationRecord.connection.execute(<<-SQL.squish)
UPDATE labels SET title = title || '_' || 'duplicate' || extract(epoch from now())
WHERE labels.id IN (#{soft_duplicates.map { |dup| dup["id"] }.join(", ")});
      SQL
    end
  end
end
