# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveInaccessibleEpicIssueLinks, schema: 20210223175130 do
  let_it_be(:users) { table(:users) }
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:projects) { table(:projects) }
  let_it_be(:issues) { table(:issues) }
  let_it_be(:epics) { table(:epics) }
  let_it_be(:epic_issues) { table(:epic_issues) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group') }
  let(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group') }
  let(:project_a) { projects.create!(name: 'project-a', path: 'project-a', namespace_id: group1.id, visibility_level: 0) }
  let(:project_b) { projects.create!(name: 'project-b', path: 'project-b', namespace_id: group1.id, visibility_level: 0) }
  let(:project_c) { projects.create!(name: 'project-c', path: 'project-c', namespace_id: group2.id, visibility_level: 0) }
  let(:epic1) { epics.create!(iid: 1, group_id: group1.id, author_id: user.id, title: 'any', title_html: 'any') }
  let(:epic2) { epics.create!(iid: 2, group_id: group2.id, author_id: user.id, title: 'any', title_html: 'any') }

  describe '#perform' do
    let!(:issue1) { issues.create!(issue_type: 0, project_id: project_a.id) }
    let!(:issue2) { issues.create!(issue_type: 0, project_id: project_b.id) }
    let!(:issue3) { issues.create!(issue_type: 0, project_id: project_c.id) }
    let!(:epic_issue1) { epic_issues.create!(issue_id: issue1.id, epic_id: epic1.id) }
    let!(:epic_issue2) { epic_issues.create!(issue_id: issue2.id, epic_id: epic1.id) }
    let!(:epic_issue3) { epic_issues.create!(issue_id: issue3.id, epic_id: epic2.id) }

    subject(:perform) { described_class.new.perform([group1.id, group2.id]) }

    context "when the issue's group is different to the epic's group" do
      before do
        project_a.update!(namespace_id: group2.id)
      end

      it 'deletes epic issue links' do
        expect { perform }.to change { epic_issues.count }.by(-1)
      end

      it 'writes log messages' do
        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:info)
          .with(message: "Deleting epic_issues", count: 1, epic_issue_ids: [epic_issue1.id])
          .once
        end

        perform
      end
    end

    context "when the issue's group is a descendant of the epic's group " do
      before do
        subgroup = namespaces.create!(name: 'subgroup', path: 'group1/subgroup', type: 'Group', parent_id: group1.id)
        project_a.update!(namespace_id: subgroup.id)
      end

      it 'does not delete epic issue links' do
        expect { perform }.not_to change { epic_issues.count }
      end
    end

    context "when the issue's group is an ancestor of the epic's group" do
      before do
        parent1 = namespaces.create!(name: 'parent1', path: 'parent1', type: 'Group')
        group1.update!(parent_id: parent1.id)
        project_a.update!(namespace_id: parent1.id)
      end

      it 'deletes epic issue links' do
        expect { perform }.to change { epic_issues.count }.by(-1)
      end
    end
  end
end
