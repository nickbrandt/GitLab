# frozen_string_literal: true

class AddLabelRestoreTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    # copy table
    execute "CREATE TABLE #{backup_labels_table_name} (LIKE #{labels_table_name} INCLUDING ALL);"

    # create foreign keys
    connection.foreign_keys(labels_table_name).each do |fk|
      fk_options = fk.options
      execute "ALTER TABLE #{backup_labels_table_name} ADD CONSTRAINT #{fk.name} FOREIGN KEY (#{fk_options[:column]}) REFERENCES #{fk.to_table}(#{fk_options[:primary_key]});"
    end

    # make the primary key a real functioning one rather than incremental
    execute "ALTER TABLE #{backup_labels_table_name} ALTER COLUMN ID DROP DEFAULT;"

    # add some fields that make changes trackable
    execute "ALTER TABLE #{backup_labels_table_name} ADD COLUMN restore_action INTEGER;"
    execute "ALTER TABLE #{backup_labels_table_name} ADD COLUMN new_title VARCHAR;"
  end

  def down
    drop_table backup_labels_table_name
  end

  private

  def labels_table_name
    :labels
  end

  def backup_labels_table_name
    :backup_labels
  end
end
