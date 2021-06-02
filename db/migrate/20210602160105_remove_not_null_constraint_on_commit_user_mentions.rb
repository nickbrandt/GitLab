# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveNotNullConstraintOnCommitUserMentions < ActiveRecord::Migration[6.1]
  def change
    change_column_null :commit_user_mentions, :note_id, true
  end
end
