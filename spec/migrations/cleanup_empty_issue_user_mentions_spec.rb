# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200229150525_cleanup_empty_issue_user_mentions')

describe CleanupEmptyIssueUserMentions, :migration, version: 20200229150525 do
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

  # these should get cleanup, by the migration
  let!(:blank_issue_user_mention1) { issue_user_mentions.create!(issue_id: resource1.id)}
  let!(:blank_issue_user_mention2) { issue_user_mentions.create!(issue_id: resource2.id)}
  let!(:blank_issue_user_mention3) { issue_user_mentions.create!(issue_id: resource3.id)}

  it 'cleans blank user mentions' do
    expect(issue_user_mentions.count).to eq 4

    migrate!

    expect(issue_user_mentions.count).to eq 1
  end
end
