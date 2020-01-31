# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200301125025_migrate_issue_notes_mentions_to_db')

describe MigrateIssueNotesMentionsToDb, :migration, version: 20200301125025 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:issue_user_mentions) { table(:issue_user_mentions) }
  let(:notes) { table(:notes) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id) }
  let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }
  let!(:issue) { issues.create!(title: "title1", title_html: 'title1', description: 'description with @root mention', project_id: project.id, author_id: user.id) }
  let!(:resource1) { notes.create!(note: 'note1 for @root to check', noteable_id: issue.id, noteable_type: 'Issue') }
  let!(:resource2) { notes.create!(note: 'note2 for @root to check', noteable_id: issue.id, noteable_type: 'Issue', system: true) }
  let!(:resource3) { notes.create!(note: 'note3 for @root to check', noteable_id: issue.id, noteable_type: 'Issue') }

  # non-migrateable resources
  # this note is already migrated, as it has a record in the issue_user_mentions table
  let!(:resource4) { notes.create!(note: 'note4 for @root to check', noteable_id: issue.id, noteable_type: 'Issue') }
  let!(:user_mention) { issue_user_mentions.create!(issue_id: issue.id, note_id: resource4.id, mentioned_users_ids: [1]) }
  # this note points to an innexistent noteable record
  let!(:resource5) { notes.create!(note: 'note5 for @root to check', noteable_id: issues.maximum(:id) + 10, noteable_type: 'Issue') }

  it_behaves_like 'schedules resource mentions migration', Issue, true
end
