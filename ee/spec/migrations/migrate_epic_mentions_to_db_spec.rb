# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191115115043_migrate_epic_mentions_to_db')

describe MigrateEpicMentionsToDb, :migration do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:epic_user_mentions) { table(:epic_user_mentions) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id, type: 'Group') }

  # migrateable resources
  let!(:resource1) { epics.create!(iid: 1, title: "title1", title_html: 'title1', description: 'epic description with @root mention', group_id: group.id, author_id: user.id) }
  let!(:resource2) { epics.create!(iid: 2, title: "title2", title_html: 'title2', description: 'epic description with @root mention', group_id: group.id, author_id: user.id) }
  let!(:resource3) { epics.create!(iid: 3, title: "title3", title_html: 'title3', description: 'epic description with @root mention', group_id: group.id, author_id: user.id) }

  # non-migrateable resources
  # this epic is already migrated, as it has a record in the epic_user_mentions table
  let!(:resource4) { epics.create!(iid: 4, title: "title3", title_html: 'title3', description: 'epic description with @root mention', group_id: group.id, author_id: user.id) }
  let!(:user_mention) { epic_user_mentions.create!(epic_id: resource4.id, mentioned_users_ids: [1]) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it_behaves_like 'schedules resource mentions migration', Epic, false
end
