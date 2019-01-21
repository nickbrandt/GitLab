class AddEpicNotesFilterToUserPreference < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class UserPreference < ActiveRecord::Base
    self.table_name = 'user_preferences'

    NOTES_FILTERS = { all_notes: 0, comments: 1 }.freeze
  end

  disable_ddl_transaction!

  def up
    add_column_with_default :user_preferences,
                            :epic_notes_filter,
                            :integer,
                            default: UserPreference::NOTES_FILTERS[:all_notes],
                            allow_null: false,
                            limit: 2
  end

  def down
    remove_column(:user_preferences, :epic_notes_filter)
  end
end
