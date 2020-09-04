# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePlacementWorker do
  describe '#perform' do
    let_it_be(:time) { Time.now.utc }
    let_it_be(:project) { create_default(:project) }
    let_it_be(:issue) { create(:issue, relative_position: nil, created_at: time) }
    let_it_be(:issue_a) { create(:issue, relative_position: nil, created_at: time - 1.minute) }
    let_it_be(:issue_b) { create(:issue, relative_position: nil, created_at: time - 6.minutes) }
    let_it_be(:issue_c) { create(:issue, relative_position: nil, created_at: time + 1.minute) }
    let_it_be(:issue_d) { create(:issue, relative_position: nil, created_at: time + 6.minutes) }
    let_it_be(:issue_e) { create(:issue, relative_position: 10, created_at: time + 3.minutes) }
    let_it_be(:issue_f) { create(:issue, relative_position: nil, created_at: time + 1.minute) }

    let_it_be(:irrelevant) { create(:issue, project: create(:project), relative_position: nil, created_at: time) }

    it 'places all issues created at most 5 minutes before this one at the end, most recent last' do
      expect do
        described_class.new.perform(issue.id)
      end.not_to change { irrelevant.reset.relative_position }

      expect(project.issues.order_relative_position_asc)
        .to eq([issue_e, issue_b, issue_a, issue, issue_c, issue_f, issue_d])
      expect(project.issues.where(relative_position: nil)).not_to exist
    end

    it 'limits the sweep to QUERY_LIMIT records' do
      issues = create_list(:issue, described_class::QUERY_LIMIT + 1, relative_position: nil)

      described_class.new.perform(issues.first.id)

      expect(project.issues.where(relative_position: nil)).to exist
    end

    it 'anticipates the failure to find the issue' do
      id = non_existing_record_id

      expect { described_class.new.perform(id) }.not_to raise_error
    end

    it 'anticipates the failure to place the issues, and schedules rebalancing' do
      allow(Issue).to receive(:move_nulls_to_end) { raise RelativePositioning::NoSpaceLeft }

      expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)
      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .with(RelativePositioning::NoSpaceLeft, issue_id: issue.id)

      described_class.new.perform(issue.id)
    end
  end
end
