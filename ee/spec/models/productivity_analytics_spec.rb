# frozen_string_literal: true

require 'spec_helper'

describe ProductivityAnalytics do
  subject(:analytics) { described_class.new(merge_requests: MergeRequest.all, sort: custom_sort) }

  let(:custom_sort) { nil }

  let(:long_mr) do
    metrics_data = {
      merged_at: 1.day.ago,
      first_comment_at: 31.days.ago,
      last_commit_at: 2.days.ago,
      commits_count: 20,
      diff_size: 310,
      modified_paths_size: 15
    }
    create(:merge_request, :merged, :with_productivity_metrics, created_at: 31.days.ago, metrics_data: metrics_data)
  end

  let(:medium_mr) do
    metrics_data = {
      merged_at: 1.day.ago,
      first_comment_at: 15.days.ago,
      last_commit_at: 2.days.ago,
      commits_count: 5,
      diff_size: 84,
      modified_paths_size: 3
    }

    create(:merge_request, :merged, :with_productivity_metrics, created_at: 15.days.ago, metrics_data: metrics_data)
  end

  let(:short_mr) do
    metrics_data = {
      merged_at: 28.days.ago,
      first_comment_at: 30.days.ago,
      last_commit_at: 28.days.ago,
      commits_count: 1,
      diff_size: 14,
      modified_paths_size: 3
    }

    create(:merge_request, :merged, :with_productivity_metrics, created_at: 31.days.ago, metrics_data: metrics_data)
  end

  let(:short_mr_2) do
    metrics_data = {
      merged_at: 28.days.ago,
      first_comment_at: 31.days.ago,
      last_commit_at: 29.days.ago,
      commits_count: 1,
      diff_size: 5,
      modified_paths_size: 1
    }

    create(:merge_request, :merged, :with_productivity_metrics, created_at: 31.days.ago, metrics_data: metrics_data)
  end

  before do
    Timecop.freeze do
      long_mr
      medium_mr
      short_mr
      short_mr_2
    end
  end

  describe '#histogram_data' do
    subject { analytics.histogram_data(type: metric) }

    context 'days_to_merge metric' do
      let(:metric) { 'days_to_merge' }

      it 'returns aggregated data per days to merge from MR creation date' do
        expect(subject).to eq(3 => 2, 14 => 1, 30 => 1)
      end
    end

    context 'time_to_first_comment metric' do
      let(:metric) { 'time_to_first_comment' }

      it 'returns aggregated data per hours from MR creation to first comment' do
        expect(subject).to eq(0 => 3, 24 => 1)
      end
    end

    context 'time_to_last_commit metric' do
      let(:metric) { 'time_to_last_commit' }

      it 'returns aggregated data per hours from first comment to last commit' do
        expect(subject).to eq(13 * 24 => 1, 29 * 24 => 1, 2 * 24 => 2)
      end
    end

    context 'time_to_merge metric' do
      let(:metric) { 'time_to_merge' }

      it 'returns aggregated data per hours from last commit to merge' do
        expect(subject).to eq(24 => 3, 0 => 1)
      end
    end

    context 'commits_count metric' do
      let(:metric) { 'commits_count' }

      it 'returns aggregated data per number of commits' do
        expect(subject).to eq(1 => 2, 5 => 1, 20 => 1)
      end
    end

    context 'loc_per_commit metric' do
      let(:metric) { 'loc_per_commit' }

      it 'returns aggregated data per number of LoC/commits_count' do
        expect(subject).to eq(15 => 1, 16 => 1, 14 => 1, 5 => 1)
      end
    end

    context 'files_touched metric' do
      let(:metric) { 'files_touched' }

      it 'returns aggregated data per number of modified files' do
        expect(subject).to eq(15 => 1, 3 => 2, 1 => 1)
      end
    end

    context 'for invalid metric' do
      let(:metric) { 'something_invalid' }

      it { is_expected.to eq nil }
    end
  end

  # Test coverage depends on #histogram_data tests. We want to avoid duplication here, so test only for 1 metric.
  describe '#scatterplot_data' do
    subject { analytics.scatterplot_data(type: 'days_to_merge') }

    it 'returns metric values for each MR' do
      expect(subject).to match(
        short_mr.id => { metric: 3, merged_at: be_like_time(short_mr.merged_at) },
        short_mr_2.id => { metric: 3, merged_at: be_like_time(short_mr_2.merged_at) },
        medium_mr.id => { metric: 14, merged_at: be_like_time(medium_mr.merged_at) },
        long_mr.id => { metric: 30, merged_at: be_like_time(long_mr.merged_at) }
      )
    end
  end

  describe '#merge_requests_extended' do
    subject { analytics.merge_requests_extended }

    it 'returns MRs data with all the metrics calculated' do
      expected_data = {
        long_mr.id => {
          'days_to_merge' => 30,
          'time_to_first_comment' => 0,
          'time_to_last_commit' => 29 * 24,
          'time_to_merge' => 24,
          'commits_count' => 20,
          'loc_per_commit' => 15,
          'files_touched' => 15
        },
        medium_mr.id => {
          'days_to_merge' => 14,
          'time_to_first_comment' => 0,
          'time_to_last_commit' => 13 * 24,
          'time_to_merge' => 24,
          'commits_count' => 5,
          'loc_per_commit' => 16,
          'files_touched' => 3
        },
        short_mr.id => {
          'days_to_merge' => 3,
          'time_to_first_comment' => 24,
          'time_to_last_commit' => 2 * 24,
          'time_to_merge' => 0,
          'commits_count' => 1,
          'loc_per_commit' => 14,
          'files_touched' => 3
        },
        short_mr_2.id => {
          'days_to_merge' => 3,
          'time_to_first_comment' => 0,
          'time_to_last_commit' => 2 * 24,
          'time_to_merge' => 24,
          'commits_count' => 1,
          'loc_per_commit' => 5,
          'files_touched' => 1
        }
      }

      expected_data.each do |mr_id, expected_attributes|
        expect(subject.detect { |mr| mr.id == mr_id}.attributes).to include(expected_attributes)
      end
    end

    context 'with custom sorting' do
      let(:custom_sort) { 'loc_per_commit_asc' }

      it 'reorders MRs according to custom sorting' do
        expect(subject).to eq [short_mr_2, short_mr, long_mr, medium_mr]
      end

      context 'with unknown sorting' do
        let(:custom_sort) { 'weird_stuff' }
        it 'does not apply custom sorting' do
          expect(subject).to eq [long_mr, medium_mr, short_mr, short_mr_2]
        end
      end
    end
  end
end
