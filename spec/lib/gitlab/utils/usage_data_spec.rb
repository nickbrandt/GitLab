# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::UsageData do
  describe '#count' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(relation).to receive(:count).and_return(1)

      expect(described_class.count(relation, batch: false)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      stub_const("Gitlab::Utils::UsageData::FALLBACK", 15)
      allow(relation).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.count(relation, batch: false)).to eq(15)
    end
  end

  describe '#distinct_count' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(relation).to receive(:distinct_count_by).and_return(1)

      expect(described_class.distinct_count(relation, batch: false)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      stub_const("Gitlab::Utils::UsageData::FALLBACK", 15)
      allow(relation).to receive(:distinct_count_by).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.distinct_count(relation, batch: false)).to eq(15)
    end
  end

  describe '#estimate_batch_distinct_count' do
    let(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE } # HyperLogLog is a probabilistic algorithm, which provides estimated data, with given error margin
    let(:relation) { double(:relation) }

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
    end

    it 'delegates counting to counter class instance' do
      buckets = instance_double(Gitlab::Database::PostgresHll::Buckets)

      expect_next_instance_of(Gitlab::Database::PostgresHll::BatchDistinctCounter, relation, 'column') do |instance|
        expect(instance).to receive(:execute)
                              .with(batch_size: nil, start: nil, finish: nil)
                              .and_return(buckets)
      end
      expect(buckets).to receive(:estimated_distinct_count).and_return(5)

      expect(described_class.estimate_batch_distinct_count(relation, 'column')).to eq(5)
    end

    it 'yield provided block with PostgresHll::Buckets' do
      buckets = Gitlab::Database::PostgresHll::Buckets.new

      allow_next_instance_of(Gitlab::Database::PostgresHll::BatchDistinctCounter) do |instance|
        allow(instance).to receive(:execute).and_return(buckets)
      end

      expect { |block| described_class.estimate_batch_distinct_count(relation, 'column', &block) }.to yield_with_args(buckets)
    end

    context 'quasi integration test for different counting parameters' do
      # HyperLogLog http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf algorithm
      # used in estimate_batch_distinct_count produce probabilistic
      # estimations of unique values present in dataset, because of that its results
      # are always off by some small factor from real value. However for given
      # dataset it provide consistent and deterministic result. In the following context
      # analyzed sets consist of values:
      # build_needs set: ['1', '2', '3', '4', '5']
      # ci_build set ['a', 'b']
      # with them, current implementation is expected to consistently report
      # 5.217656147118495 and 2.0809220082170614 values
      # This test suite is expected to assure, that HyperLogLog implementation
      # behaves consistently between changes made to other parts of codebase.
      # In case of fine tuning or changes to HyperLogLog algorithm implementation
      # one should run in depth analysis of accuracy with supplementary rake tasks
      # currently under implementation at https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51118
      # and adjust used values in this context accordingly.
      let_it_be(:build) { create(:ci_build, name: 'a') }
      let_it_be(:another_build) { create(:ci_build, name: 'b') }

      let(:model) { Ci::BuildNeed }
      let(:column) { :name }
      let(:build_needs_estimated_cardinality) { 5.217656147118495 }
      let(:ci_builds_estimated_cardinality) { 2.0809220082170614 }

      context 'different counting parameters' do
        before_all do
          1.upto(3) { |i| create(:ci_build_need, name: i, build: build) }
          4.upto(5) { |i| create(:ci_build_need, name: i, build: another_build) }
        end

        it 'counts with symbol passed in column argument' do
          expect(described_class.estimate_batch_distinct_count(model, column)).to eq(build_needs_estimated_cardinality)
        end

        it 'counts with string passed in column argument' do
          expect(described_class.estimate_batch_distinct_count(model, column.to_s)).to eq(build_needs_estimated_cardinality)
        end

        it 'counts with table.column passed in column argument' do
          expect(described_class.estimate_batch_distinct_count(model, "#{model.table_name}.#{column}")).to eq(build_needs_estimated_cardinality)
        end

        it 'counts with Arel passed in column argument' do
          expect(described_class.estimate_batch_distinct_count(model, model.arel_table[column])).to eq(build_needs_estimated_cardinality)
        end

        it 'counts over joined relations' do
          expect(described_class.estimate_batch_distinct_count(model.joins(:build), "ci_builds.name")).to eq(ci_builds_estimated_cardinality)
        end

        it 'counts with :column field with batch_size of 50K' do
          expect(described_class.estimate_batch_distinct_count(model, column, batch_size: 50_000)).to eq(build_needs_estimated_cardinality)
        end

        it 'counts with different number of batches and aggregates total result' do
          stub_const('Gitlab::Database::PostgresHll::BatchDistinctCounter::MIN_REQUIRED_BATCH_SIZE', 0)

          [1, 2, 4, 5, 6].each { |i| expect(described_class.estimate_batch_distinct_count(model, column, batch_size: i)).to eq(build_needs_estimated_cardinality) }
        end

        it 'counts with a start and finish' do
          expect(described_class.estimate_batch_distinct_count(model, column, start: model.minimum(:id), finish: model.maximum(:id))).to eq(build_needs_estimated_cardinality)
        end
      end
    end

    describe 'error handling' do
      before do
        stub_const("Gitlab::Utils::UsageData::FALLBACK", 3)
        stub_const("Gitlab::Utils::UsageData::DISTRIBUTED_HLL_FALLBACK", 4)
      end

      it 'returns fallback if counter raises WRONG_CONFIGURATION_ERROR' do
        expect(described_class.estimate_batch_distinct_count(relation, 'id', start: 1, finish: 0)).to eq 3
      end

      it 'returns default fallback value when counting fails due to database error' do
        allow(Gitlab::Database::PostgresHll::BatchDistinctCounter).to receive(:new).and_raise(ActiveRecord::StatementInvalid.new(''))

        expect(described_class.estimate_batch_distinct_count(relation)).to eq(3)
      end

      it 'logs error and returns DISTRIBUTED_HLL_FALLBACK value when counting raises any error', :aggregate_failures do
        error = StandardError.new('')
        allow(Gitlab::Database::PostgresHll::BatchDistinctCounter).to receive(:new).and_raise(error)

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(error)
        expect(described_class.estimate_batch_distinct_count(relation)).to eq(4)
      end
    end
  end

  describe '#sum' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(Gitlab::Database::BatchCount)
        .to receive(:batch_sum)
        .with(relation, :column, batch_size: 100, start: 2, finish: 3)
        .and_return(1)

      expect(described_class.sum(relation, :column, batch_size: 100, start: 2, finish: 3)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      stub_const("Gitlab::Utils::UsageData::FALLBACK", 15)
      allow(Gitlab::Database::BatchCount)
        .to receive(:batch_sum)
        .and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.sum(relation, :column)).to eq(15)
    end
  end

  describe '#alt_usage_data' do
    it 'returns the fallback when it gets an error' do
      expect(described_class.alt_usage_data { raise StandardError } ).to eq(-1)
    end

    it 'returns the evaluated block when give' do
      expect(described_class.alt_usage_data { Gitlab::CurrentSettings.uuid } ).to eq(Gitlab::CurrentSettings.uuid)
    end

    it 'returns the value when given' do
      expect(described_class.alt_usage_data(1)).to eq 1
    end
  end

  describe '#redis_usage_data' do
    context 'with block given' do
      it 'returns the fallback when it gets an error' do
        expect(described_class.redis_usage_data { raise ::Redis::CommandError } ).to eq(-1)
      end

      it 'returns the evaluated block when given' do
        expect(described_class.redis_usage_data { 1 }).to eq(1)
      end
    end

    context 'with counter given' do
      it 'returns the falback values for all counter keys when it gets an error' do
        allow(::Gitlab::UsageDataCounters::WikiPageCounter).to receive(:totals).and_raise(::Redis::CommandError)
        expect(described_class.redis_usage_data(::Gitlab::UsageDataCounters::WikiPageCounter)).to eql(::Gitlab::UsageDataCounters::WikiPageCounter.fallback_totals)
      end

      it 'returns the totals when couter is given' do
        allow(::Gitlab::UsageDataCounters::WikiPageCounter).to receive(:totals).and_return({ wiki_pages_create: 2 })
        expect(described_class.redis_usage_data(::Gitlab::UsageDataCounters::WikiPageCounter)).to eql({ wiki_pages_create: 2 })
      end
    end
  end

  describe '#with_prometheus_client' do
    shared_examples 'query data from Prometheus' do
      it 'yields a client instance and returns the block result' do
        result = described_class.with_prometheus_client { |client| client }

        expect(result).to be_an_instance_of(Gitlab::PrometheusClient)
      end
    end

    shared_examples 'does not query data from Prometheus' do
      it 'returns nil by default' do
        result = described_class.with_prometheus_client { |client| client }

        expect(result).to be_nil
      end

      it 'returns fallback if provided' do
        result = described_class.with_prometheus_client(fallback: []) { |client| client }

        expect(result).to eq([])
      end
    end

    shared_examples 'try to query Prometheus with given address' do
      context 'Prometheus is ready' do
        before do
          stub_request(:get, /\/-\/ready/)
              .to_return(status: 200, body: 'Prometheus is Ready.\n')
        end

        context 'Prometheus is reachable through HTTPS' do
          it_behaves_like 'query data from Prometheus'
        end

        context 'Prometheus is not reachable through HTTPS' do
          before do
            stub_request(:get, /https:\/\/.*/).to_raise(Errno::ECONNREFUSED)
          end

          context 'Prometheus is reachable through HTTP' do
            it_behaves_like 'query data from Prometheus'
          end

          context 'Prometheus is not reachable through HTTP' do
            before do
              stub_request(:get, /http:\/\/.*/).to_raise(Errno::ECONNREFUSED)
            end

            it_behaves_like 'does not query data from Prometheus'
          end
        end
      end

      context 'Prometheus is not ready' do
        before do
          stub_request(:get, /\/-\/ready/)
              .to_return(status: 503, body: 'Service Unavailable')
        end

        it_behaves_like 'does not query data from Prometheus'
      end
    end

    context 'when Prometheus server address is available from settings' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(true)
        expect(Gitlab::Prometheus::Internal).to receive(:uri).and_return('http://prom:9090')
      end

      it_behaves_like 'try to query Prometheus with given address'
    end

    context 'when Prometheus server address is available from Consul service discovery' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)
        expect(Gitlab::Consul::Internal).to receive(:api_url).and_return('http://localhost:8500')
        expect(Gitlab::Consul::Internal).to receive(:discover_prometheus_server_address).and_return('prom:9090')
      end

      it_behaves_like 'try to query Prometheus with given address'
    end

    context 'when Prometheus server address is not available' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)
        expect(Gitlab::Consul::Internal).to receive(:api_url).and_return(nil)
      end

      it_behaves_like 'does not query data from Prometheus'
    end
  end

  describe '#measure_duration' do
    it 'returns block result and execution duration' do
      allow(Process).to receive(:clock_gettime).and_return(1, 3)

      result, duration = described_class.measure_duration { 42 }

      expect(result).to eq(42)
      expect(duration).to eq(2)
    end
  end

  describe '#with_finished_at' do
    it 'adds a timestamp to the hash yielded by the block' do
      freeze_time do
        result = described_class.with_finished_at(:current_time) { { a: 1 } }

        expect(result).to eq(a: 1, current_time: Time.current)
      end
    end
  end

  describe '#track_usage_event' do
    let(:value) { '9f302fea-f828-4ca9-aef4-e10bd723c0b3' }
    let(:event_name) { 'incident_management_alert_status_changed' }
    let(:unknown_event) { 'unknown' }

    it 'tracks redis hll event' do
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(event_name, values: value)

      described_class.track_usage_event(event_name, value)
    end

    it 'raise an error for unknown event' do
      expect { described_class.track_usage_event(unknown_event, value) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
    end
  end

  describe '#save_aggregated_metrics', :clean_gitlab_redis_shared_state do
    let(:timestamp) { Time.current.to_i }
    let(:time_period) { { created_at: 7.days.ago..Date.current } }
    let(:metric_name) { 'test_metric' }
    let(:method_params) do
      {
        metric_name: metric_name,
        time_period: time_period,
        recorded_at_timestamp: timestamp,
        data: data
      }
    end

    context 'with compatible data argument' do
      let(:data) { ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1) }

      it 'persists serialized data in Redis' do
        time_period_name = 'weekly'

        expect(described_class).to receive(:time_period_to_human_name).with(time_period).and_return(time_period_name)
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:set).with("#{metric_name}_#{time_period_name}-#{timestamp}", '{"141":1,"56":1}', ex: 80.hours)
        end

        described_class.save_aggregated_metrics(**method_params)
      end

      context 'error handling' do
        before do
          allow(Gitlab::Redis::SharedState).to receive(:with).and_raise(::Redis::CommandError)
        end

        it 'rescues and reraise ::Redis::CommandError for development and test environments' do
          expect { described_class.save_aggregated_metrics(**method_params) }.to raise_error ::Redis::CommandError
        end

        context 'for environment different than development' do
          before do
            stub_rails_env('production')
          end

          it 'rescues ::Redis::CommandError' do
            expect { described_class.save_aggregated_metrics(**method_params) }.not_to raise_error
          end
        end
      end
    end

    context 'with incompatible data argument' do
      let(:data) { 1 }

      context 'for environment different than development' do
        before do
          stub_rails_env('production')
        end

        it 'does not persist data in Redis' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).not_to receive(:set)
          end

          described_class.save_aggregated_metrics(**method_params)
        end
      end

      it 'raises error for development environment' do
        expect { described_class.save_aggregated_metrics(**method_params) }.to raise_error /Unsupported data type/
      end
    end
  end

  describe '#time_period_to_human_name' do
    it 'translates empty time period as all_time' do
      expect(described_class.time_period_to_human_name({})).to eql 'all_time'
    end

    it 'translates time period not longer than 7 days as weekly', :aggregate_failures do
      days_6_time_period = 6.days.ago..Date.current
      days_7_time_period = 7.days.ago..Date.current

      expect(described_class.time_period_to_human_name(column_name: days_6_time_period)).to eql 'weekly'
      expect(described_class.time_period_to_human_name(column_name: days_7_time_period)).to eql 'weekly'
    end

    it 'translates time period longer than 7 days as monthly', :aggregate_failures do
      days_8_time_period = 8.days.ago..Date.current
      days_31_time_period = 31.days.ago..Date.current

      expect(described_class.time_period_to_human_name(column_name: days_8_time_period)).to eql 'monthly'
      expect(described_class.time_period_to_human_name(column_name: days_31_time_period)).to eql 'monthly'
    end
  end
end
