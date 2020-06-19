# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataConcerns::Topology do
  include UsageDataHelpers

  describe '#topology_usage_data' do
    subject { Class.new.extend(described_class).topology_usage_data }

    before do
      # this pins down time shifts when benchmarking durations
      allow(Process).to receive(:clock_gettime).and_return(0)
    end

    context 'when embedded Prometheus server is enabled' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(true)
        expect(Gitlab::Prometheus::Internal).to receive(:uri).and_return('http://prom:9090')
      end

      context 'tracking node metrics' do
        it 'contains node level metrics for each instance' do
          expect_prometheus_api_to receive_usage_ping_query

          expect(subject[:topology]).to eq({
            duration_s: 0,
            application_requests_per_hour: 40044,
            nodes: [
              {
                node_memory_total_bytes: 512,
                node_cpus: 8,
                node_services: [
                  {
                    name: 'web',
                    process_count: 10,
                    process_memory_rss: 300,
                    process_memory_uss: 301,
                    process_memory_pss: 302
                  },
                  {
                    name: 'node-exporter',
                    process_count: 1,
                    process_memory_rss: 304
                  },
                  {
                    name: 'workhorse',
                    process_count: 4,
                    process_memory_rss: 303
                  }
                ]
              },
              {
                node_memory_total_bytes: 1024,
                node_cpus: 16,
                node_services: [
                  {
                    name: 'node-exporter',
                    process_count: 1,
                    process_memory_rss: 401
                  },
                  {
                    name: 'gitaly',
                    process_count: 1,
                    process_memory_rss: 400
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and some node memory metrics are missing' do
        it 'reports only the available metrics' do
          expect_prometheus_api_to receive_usage_ping_query(fixture: 'usage_ping_metrics_missing_data')

          expect(subject[:topology]).to eq({
            duration_s: 0,
            application_requests_per_hour: -1,
            nodes: [
              {
                node_cpus: 8,
                node_services: [
                  {
                    name: 'web',
                    process_count: 10,
                    process_memory_uss: 301,
                    process_memory_pss: 302
                  },
                  {
                    name: 'node-exporter',
                    process_count: 1
                  },
                  {
                    name: 'workhorse',
                    process_count: 4,
                    process_memory_rss: 303
                  }
                ]
              },
              {
                node_cpus: 16,
                node_services: [
                  {
                    name: 'gitaly',
                    process_count: 1,
                    process_memory_rss: 400
                  }
                ]
              }
            ]
          })
        end
      end

      context 'and no results are found' do
        it 'reports fallback values' do
          expect_prometheus_api_to receive_usage_ping_query(fixture: 'usage_ping_metrics_empty_response')

          expect(subject[:topology]).to eq({
            application_requests_per_hour: -1,
            duration_s: 0,
            nodes: []
          })
        end
      end

      context 'and a connection error is raised' do
        it 'does not report anything' do
          expect_prometheus_api_to receive(:query).and_raise('Connection failed')

          expect(subject[:topology]).to eq({ duration_s: 0 })
        end
      end
    end

    context 'when embedded Prometheus server is disabled' do
      it 'does not report anything' do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)

        expect(subject[:topology]).to eq({ duration_s: 0 })
      end
    end
  end

  def receive_usage_ping_query(fixture: 'usage_ping_metrics')
    receive(:query)
      .with('{__name__ =~ "^gitlab_usage_ping:.+"}')
      .and_return(Gitlab::Json.parse(
        IO.read(Rails.root.join('spec', 'fixtures', 'prometheus', "#{fixture}.json"))
      ).dig('data', 'result'))
  end
end
