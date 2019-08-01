# frozen_string_literal: true

require 'spec_helper'

describe Analytics::ProductivityRecalculateService do
  describe '#perform' do
    let(:perform) { subject.perform(merged_at_after) }
    let(:merged_at_after) { 6.months.ago }

    let(:calculator_mock) { instance_double('Analytics::ProductivityCalculator', productivity_data: { commits_count: 21 }) }

    let(:merged_mr) { create(:merge_request, :merged, :with_productivity_metrics, metrics_data: { merged_at: 3.months.ago }) }
    let(:open_mr) { create(:merge_request) }
    let(:old_mr) { create(:merge_request, :merged, :with_productivity_metrics, metrics_data: { merged_at: 1.year.ago }) }

    before do
      allow(Analytics::ProductivityCalculator).to receive(:new).and_return(calculator_mock)
    end

    it 'updates all MRs merged after given date' do
      merged_mr
      expect do
        perform
        merged_mr.metrics.reload
      end.to change { merged_mr.metrics.commits_count }.to(21)
    end

    it 'does not update MRs merged before given date' do
      old_mr
      expect do
        perform
        old_mr.metrics.reload
      end.not_to change { old_mr.metrics.commits_count }
    end

    it 'does not update open MRs' do
      open_mr
      expect do
        perform
        open_mr.metrics.reload
      end.not_to change { open_mr.metrics.commits_count }
    end
  end
end
