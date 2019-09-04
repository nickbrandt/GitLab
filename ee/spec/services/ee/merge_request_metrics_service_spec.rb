# frozen_string_literal: true

require 'spec_helper'

describe EE::MergeRequestMetricsService do
  subject { MergeRequestMetricsService.new(merge_request.metrics) }

  describe '#merge' do
    let(:merge_request) { create(:merge_request, :merged) }
    let(:expected_commit_count) { 21 }

    it 'saves metrics with productivity_data' do
      allow(merge_request).to receive(:commits_count).and_return(expected_commit_count)

      expect do
        subject.merge(instance_double('Event', author_id: merge_request.author.id, created_at: Time.now))
        merge_request.metrics.reload
      end.to change { merge_request.metrics.commits_count }.to(expected_commit_count)
    end
  end
end
