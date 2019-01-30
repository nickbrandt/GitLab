# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('ee', 'db', 'migrate', '20190114040405_consume_remaining_migrate_approver_to_approval_rules_in_batch_jobs.rb')

describe ConsumeRemainingMigrateApproverToApprovalRulesInBatchJobs, :migration do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:approvers) { table(:approvers) }
  let(:approver_groups) { table(:approver_groups) }
  let(:migrator) { double(:migrator) }

  describe '#up' do
    before do
      stub_const('ConsumeRemainingMigrateApproverToApprovalRulesInBatchJobs::JOIN_SIZE', 6)
      stub_const('ConsumeRemainingMigrateApproverToApprovalRulesInBatchJobs::BOUND_SIZE', 100)
      allow(Gitlab::BackgroundMigration::MigrateApproverToApprovalRules).to receive(:new).and_return(migrator)

      namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab')
      projects.create!(id: 101, namespace_id: 11, name: 'gitlab', path: 'gitlab')

      namespaces.create!(id: 12, name: 'gitlab', path: 'gitlab')

      (1..101).each do |id|
        merge_requests.create!(id: id, target_project_id: 101, source_project_id: 101, target_branch: 'feature', source_branch: 'master', state: 'merged')

        if id.odd?
          approvers.create!(id: id, target_id: id, target_type: 'MergeRequest', user_id: 1)
        else
          approver_groups.create!(id: id, target_id: id, target_type: 'MergeRequest', group_id: 12)
        end
      end
    end

    it "migrates unmigrated merge requests" do
      (1..101).each do |id|
        expect(migrator).to receive(:perform).with('MergeRequest', id)
      end

      migrate!
    end
  end
end
