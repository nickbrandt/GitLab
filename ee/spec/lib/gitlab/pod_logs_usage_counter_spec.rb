# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PodLogsUsageCounter, :clean_gitlab_redis_shared_state do
  describe '.increment' do
    it 'intializes and increments the counter for the project by 1' do
      expect do
        described_class.increment(12)
      end.to change { described_class.usage_totals[12] }.from(nil).to(1)
    end
  end

  describe '.usage_totals' do
    context 'when the feature has not been used' do
      it 'returns the total counts and counts per project' do
        expect(described_class.usage_totals.keys).to eq([:total])
        expect(described_class.usage_totals[:total]).to eq(0)
      end
    end

    context 'when the feature has been used in multiple projects' do
      before do
        described_class.increment(12)
        described_class.increment(16)
      end

      it 'returns the total counts and counts per project' do
        expect(described_class.usage_totals[12]).to eq(1)
        expect(described_class.usage_totals[16]).to eq(1)
        expect(described_class.usage_totals[:total]).to eq(2)
      end
    end
  end
end
