# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuePlacementWorker do
  describe '#perform' do
    let_it_be(:project) { create_default(:project) }
    let_it_be(:issue) { create(:issue, relative_position: nil) }
    let_it_be(:issue_a) { create(:issue, relative_position: nil, created_at: issue.created_at - 1.minute) }
    let_it_be(:issue_b) { create(:issue, relative_position: nil, created_at: issue.created_at - 6.minutes) }
    let_it_be(:issue_c) { create(:issue, relative_position: nil, created_at: issue.created_at + 1.minute) }
    let_it_be(:issue_d) { create(:issue, relative_position: nil, created_at: issue.created_at + 6.minutes) }
    let_it_be(:issue_e) { create(:issue, relative_position: 10, created_at: issue.created_at + 3.minutes) }

    let_it_be(:irrelevant) { create(:issue, project: create(:project), created_at: issue.created_at - 30.seconds) }

    it 'places all issues created at most 5 minutes before this one at the end, most recent last' do
      described_class.new.perform(issue.id, :end)

      expect(project.issues.order_relative_position_asc)
        .to eq([issue_e, issue_a, issue, issue_c, issue_d, issue_b])
    end

    it 'places all issues created at most 5 minutes before this one at the start, most recent first' do
      described_class.new.perform(issue.id, :start)

      expect(project.issues.order_relative_position_asc)
        .to eq([issue_d, issue_c, issue, issue_a, issue_e, issue_b])
    end

    it 'anticipates the failure to find the issue' do
      id = non_existing_record_id

      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .with(ActiveRecord::RecordNotFound, issue_id: id, placement: :end)

      described_class.new.perform(id, :end)
    end

    it 'anticipates the failure to place the issues, and schedules rebalancing' do
      allow(Issue).to receive(:move_nulls_to_end) { raise RelativePositioning::NoSpaceLeft }

      expect(IssueRebalancingWorker).to receive(:perform_async).with(nil, project.id)
      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .with(RelativePositioning::NoSpaceLeft, issue_id: issue.id, placement: :end)

      described_class.new.perform(issue.id, :end)
    end
  end
end
