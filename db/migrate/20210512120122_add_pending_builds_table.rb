# frozen_string_literal: true

class AddPendingBuildsTable < ActiveRecord::Migration[6.0]
  def up
    create_table :ci_pending_builds, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :build, primary_key: true, default: nil, index: false, foreign_key: { to_table: :ci_builds, on_delete: :cascade }
      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }
    end
  end

  def down
    drop_table :ci_pending_builds
  end
end
