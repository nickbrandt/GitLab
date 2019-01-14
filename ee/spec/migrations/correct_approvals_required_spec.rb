# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20190114040404_correct_approvals_required.rb')

describe CorrectApprovalsRequired, :migration do
  let(:migration) { described_class.new }

  describe '#up' do
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:merge_requests) { table(:merge_requests) }
    let(:approval_merge_request_rules) { table(:approval_merge_request_rules) }
    let(:approval_merge_request_rule_sources) { table(:approval_merge_request_rule_sources) }
    let(:approval_project_rules) { table(:approval_project_rules) }

    before do
      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab')
      projects.create!(id: 101, namespace_id: 11, name: 'gitlab', path: 'gitlab')
      merge_requests.create!(id: 1, target_project_id: 101, source_project_id: 101, target_branch: 'feature', source_branch: 'master', state: 'merged')

      # When approvals_required is 0
      approval_project_rules.create!(id: 1, project_id: 101, approvals_required: 3, name: 'Rule1')
      approval_merge_request_rules.create!(id: 1, merge_request_id: 1, approvals_required: 0, name: 'Default')
      approval_merge_request_rule_sources.create!(id: 1, approval_merge_request_rule_id: 1, approval_project_rule_id: 1)

      # When approvals_required is not 0
      approval_project_rules.create!(id: 2, project_id: 101, approvals_required: 3, name: 'Rule2')
      approval_merge_request_rules.create!(id: 2, merge_request_id: 1, approvals_required: 5, name: 'Default')
      approval_merge_request_rule_sources.create!(id: 2, approval_merge_request_rule_id: 2, approval_project_rule_id: 2)

      # When MR rule does not have project rule
      approval_merge_request_rules.create!(id: 3, merge_request_id: 1, approvals_required: 0, name: 'Rule3')
    end

    it "updates approvals_required when it is 0 and lower than that of the project rule's" do
      migrate!

      expect(approval_merge_request_rules.where(id: 1).pluck(:approvals_required)).to contain_exactly(3)
      expect(approval_merge_request_rules.where(id: 2).pluck(:approvals_required)).to contain_exactly(5)
      expect(approval_merge_request_rules.where(id: 3).pluck(:approvals_required)).to contain_exactly(0)
    end
  end
end
