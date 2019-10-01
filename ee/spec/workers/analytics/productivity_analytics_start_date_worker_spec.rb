# frozen_string_literal: true

require 'spec_helper'

describe Analytics::ProductivityAnalyticsStartDateWorker do
  before do
    ApplicationSetting.create_from_defaults
  end

  def create_mr(metrics_data)
    create(:merge_request, :merged, :with_productivity_metrics, metrics_data: metrics_data)
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    context 'without PA data present' do
      it 'updates with Time.now' do
        expect { perform }
          .to change { ApplicationSetting.current_without_cache.productivity_analytics_start_date }
                .to(be_like_time(Time.now))
      end
    end

    context 'with PA data present' do
      before do
        create_mr(merged_at: Time.parse('2019-09-09'), commits_count: nil)
        create_mr(merged_at: Time.parse('2019-10-10'), commits_count: 5)
        create_mr(merged_at: Time.parse('2019-11-11'), commits_count: 10)
      end

      it 'updates start date with merged_at of first MR with PA data' do
        expect { perform }
          .to change { ApplicationSetting.current_without_cache.productivity_analytics_start_date }
                .to(be_like_time(Time.parse('2019-10-10')))
      end
    end

    it 'does nothing when PA start date value is present' do
      ApplicationSetting.current_without_cache.update!(productivity_analytics_start_date: 1.day.ago)

      expect { perform }
        .not_to change { ApplicationSetting.current_without_cache.productivity_analytics_start_date }
    end

    it 'expires application setting cache' do
      expect(ApplicationSetting).to receive(:expire).once

      perform
    end
  end
end
