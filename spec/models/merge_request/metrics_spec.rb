# frozen_string_literal: true

require 'spec_helper'

describe MergeRequest::Metrics do
  subject { described_class.new }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:latest_closed_by).class_name('User') }
    it { is_expected.to belong_to(:merged_by).class_name('User') }
  end

  describe 'scopes' do
    describe '.merged_after' do
      it 'returns metrics merged after specified date' do
        create(:merge_request)
        merged_mr = create(:merge_request).tap { |mr| mr.metrics.update(merged_at: 1.day.ago) }
        create(:merge_request).tap { |mr| mr.metrics.update(merged_at: 1.year.ago) }

        expect(described_class.merged_after(1.month.ago)).to match_array(merged_mr.metrics)
      end
    end
  end
end
