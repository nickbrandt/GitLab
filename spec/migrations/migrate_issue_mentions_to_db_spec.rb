# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200229161025_migrate_issue_mentions_to_db')

describe MigrateIssueMentionsToDb, :migration, version: 20200229161025 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:issue_user_mentions) { table(:issue_user_mentions) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id) }
  let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }

  # migrateable resources
  let!(:resource1) { issues.create!(title: "title1", title_html: 'title1', description: 'description with @root mention', project_id: project.id, author_id: user.id) }
  let!(:resource2) { issues.create!(title: "title2", title_html: "title2", description: 'description with @group mention', project_id: project.id, author_id: user.id) }
  let!(:resource3) { issues.create!(title: "title3", title_html: "title3", description: 'description with @project mention', project_id: project.id, author_id: user.id) }

  # non-migrateable resources
  # this issue is already migrated, as it has a record in the issue_user_mentions table
  let!(:resource4) { issues.create!(title: "title4", title_html: "title4", description: 'description with @project mention', project_id: project.id, author_id: user.id) }
  let!(:user_mention) { issue_user_mentions.create!(issue_id: resource4.id, mentioned_users_ids: [1]) }
  # this issue has no mentions so should be filtered out
  let!(:resource5) { issues.create!(title: "title5", title_html: "title5", description: 'description with no mention', project_id: project.id, author_id: user.id) }

  it_behaves_like 'schedules resource mentions migration', Issue, false
end
