# frozen_string_literal: true

require 'spec_helper'

describe EE::MergeRequestMetricsService do
  subject { MergeRequestMetricsService.new(merge_request.metrics) }

  describe '#merge' do
    let(:merge_request) { create(:merge_request, :merged) }

    it 'saves metrics with productivity_data' do
      allow(merge_request).to receive(:commits_count).and_return(21)

      expect do
        subject.merge(double(author_id: merge_request.author.id, created_at: Time.now))
        merge_request.metrics.reload
      end.to change { merge_request.metrics.commits_count }.to(21)
    end
  end
end
