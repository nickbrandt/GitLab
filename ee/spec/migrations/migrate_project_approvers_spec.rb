# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20181204040404_migrate_project_approvers.rb')

describe MigrateProjectApprovers, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }
    let(:approvers) { table(:approvers) }
    let(:approval_project_rules) { table(:approval_project_rules) }
    let(:approval_project_rules_users) { table(:approval_project_rules_users) }
    let(:users) { table(:users) }

    before do
      namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')
      projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 1)
      projects.create!(id: 124, name: 'gitlab2', path: 'gitlab2', namespace_id: 1)

      users.create(id: 1, name: 'user1', email: 'user1@example.com', projects_limit: 0)
      users.create(id: 2, name: 'user2', email: 'user2@example.com', projects_limit: 0)

      approvers.create!(target_id: 123, target_type: 'Project', user_id: 1)
      approvers.create!(target_id: 124, target_type: 'Project', user_id: 2)
    end

    it 'creates approval rules and its associations' do
      migrate!

      expect(approval_project_rules.pluck(:project_id)).to eq([123, 124])

      rule_ids = approval_project_rules.pluck(:id)

      expect(approval_project_rules_users.where(approval_project_rule_id: rule_ids.first).pluck(:user_id)).to contain_exactly(1)
      expect(approval_project_rules_users.where(approval_project_rule_id: rule_ids.last).pluck(:user_id)).to contain_exactly(2)
    end
  end
end
