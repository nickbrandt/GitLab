# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20210223175130_delete_inconsistent_epic_issue_links.rb')

RSpec.describe DeleteInconsistentEpicIssueLinks do
  let_it_be(:users) { table(:users) }
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:issues) { table(:issues) }
  let_it_be(:epics) { table(:epics) }
  let_it_be(:epic_issues) { table(:epic_issues) }

  before do
    allow(Gitlab).to receive(:ee?).and_return(ee?)
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  context 'when the Gitlab instance is CE' do
    let(:ee?) { false }

    it 'does not run the migration' do
      expect { migrate! }.not_to change { BackgroundMigrationWorker.jobs.size }
    end
  end

  context 'when the Gitlab instance is EE' do
    let(:ee?) { true }
    let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
    let(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
    let(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group') }
    let(:project_a) { projects.create!(name: 'project-a', path: 'project-a', namespace_id: group1.id, visibility_level: 0) }
    let(:project_b) { projects.create!(name: 'project-b', path: 'project-b', namespace_id: group2.id, visibility_level: 0) }

    before do
      epic1 = epics.create!(iid: 1, group_id: group1.id, author_id: user.id, title: 'epic1', title_html: 'epic1')
      epic2 = epics.create!(iid: 2, group_id: group2.id, author_id: user.id, title: 'epic2', title_html: 'epic2')
      issue1 = issues.create!(issue_type: 0, project_id: project_a.id)
      issue2 = issues.create!(issue_type: 0, project_id: project_b.id)
      epic_issues.create!(issue_id: issue1.id, epic_id: epic1.id)
      epic_issues.create!(issue_id: issue2.id, epic_id: epic2.id)
    end

    it 'schedules the background jobs', :aggregate_failures do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, [group1.id])
      expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, [group2.id])
    end
  end
end
