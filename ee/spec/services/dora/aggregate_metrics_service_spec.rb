# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::AggregateMetricsService do
  let(:service) { described_class.new(container: container, current_user: user, params: params) }

  describe '#execute' do
    subject { service.execute }

    around do |example|
      freeze_time do
        example.run
      end
    end

    shared_examples_for 'request failure' do
      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(message)
        expect(subject[:http_status]).to eq(http_status)
      end
    end

    context 'when container is project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:production) { create(:environment, :production, project: project) }
      let_it_be(:staging) { create(:environment, :staging, project: project) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:guest) { create(:user) }
      let(:container) { project }
      let(:user) { maintainer }
      let(:params) { { metric: 'deployment_frequency' }.merge(extra_params) }
      let(:extra_params) { {} }

      before_all do
        project.add_maintainer(maintainer)
        project.add_guest(guest)

        create(:dora_daily_metrics, deployment_frequency: 2, environment: production)
        create(:dora_daily_metrics, deployment_frequency: 1, environment: staging)
      end

      before do
        stub_licensed_features(dora4_analytics: true)
      end

      it 'returns the aggregated data' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:data]).to eq([{ Time.current.to_date.to_s => 2 }])
      end

      context 'when interval is monthly' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_MONTHLY } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to eq([{ Time.current.beginning_of_month.to_date.to_s => 2 }])
        end
      end

      context 'when interval is all' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_ALL } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to eq(2)
        end
      end

      context 'when environment tier is changed' do
        let(:extra_params) { { environment_tier: 'staging' } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to eq([{ Time.current.to_date.to_s => 1 }])
        end
      end

      context 'when data range is too wide' do
        let(:extra_params) { { start_date: 1.year.ago.to_date } }

        it_behaves_like 'request failure' do
          let(:message) { "Date range must be shorter than #{described_class::MAX_RANGE} days." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when start date is later than end date' do
        let(:extra_params) { { end_date: 1.year.ago.to_date } }

        it_behaves_like 'request failure' do
          let(:message) { 'The start date must be ealier than the end date.' }
          let(:http_status) { :bad_request }
        end
      end

      context 'when interval is invalid' do
        let(:extra_params) { { interval: 'unknown' } }

        it_behaves_like 'request failure' do
          let(:message) { "The interval must be one of #{::Dora::DailyMetrics::AVAILABLE_INTERVALS.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when metric is invalid' do
        let(:extra_params) { { metric: 'unknown' } }

        it_behaves_like 'request failure' do
          let(:message) { "The metric must be one of #{::Dora::DailyMetrics::AVAILABLE_METRICS.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when params is empty' do
        let(:params) { {} }

        it_behaves_like 'request failure' do
          let(:message) { "The metric must be one of #{::Dora::DailyMetrics::AVAILABLE_METRICS.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when environment tier is invalid' do
        let(:extra_params) { { environment_tier: 'unknown' } }

        it_behaves_like 'request failure' do
          let(:message) { "The environment tier must be one of #{Environment.tiers.keys.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when guest user' do
        let(:user) { guest }

        it_behaves_like 'request failure' do
          let(:message) { 'You do not have permission to access dora metrics.' }
          let(:http_status) { :unauthorized }
        end
      end
    end

    context 'when container is group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:guest) { create(:user) }
      let(:container) { group }
      let(:user) { maintainer }
      let(:params) { { metric: 'deployment_frequency' } }

      it_behaves_like 'request failure' do
        let(:message) { 'Container must be a project.' }
        let(:http_status) { :bad_request }
      end
    end
  end
end
