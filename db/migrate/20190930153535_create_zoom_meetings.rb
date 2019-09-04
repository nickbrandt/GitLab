# frozen_string_literal: true

class CreateZoomMeetings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ZOOM_MEETING_STATUS_ADDED = 1

  def change
    create_table :zoom_meetings do |t|
      t.integer :project_id, null: false, index: true
      t.integer :issue_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.integer :issue_status, limit: 2, default: 1, null: false
      t.string :url, limit: 255

      t.foreign_key :projects, on_delete: :cascade
      t.foreign_key :issues, on_delete: :cascade

      t.index [:issue_id, :issue_status], unique: true,
        where: "issue_status = #{ZOOM_MEETING_STATUS_ADDED}"
    end
  end
end
