# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Samplers::DatabaseSampler do
  subject { described_class.new(described_class::SAMPLING_INTERVAL_SECONDS) }

  describe '#sample' do
    before do
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        allow(subject.metrics[metric]).to receive(:set)
      end
    end

    context 'for Geo::TrackingBase', :geo do
      let(:labels) { a_hash_including(class: 'Geo::TrackingBase', host: anything, port: anything) }

      context 'when Geo is enabled' do
        it 'samples connection pool statistics' do
          expect(subject.metrics[:size]).to receive(:set).with(labels, a_value >= 1)
          expect(subject.metrics[:connections]).to receive(:set).with(labels, a_value >= 0)
          expect(subject.metrics[:busy]).to receive(:set).with(labels, a_value >= 0)
          expect(subject.metrics[:dead]).to receive(:set).with(labels, a_value >= 0)
          expect(subject.metrics[:waiting]).to receive(:set).with(labels, a_value >= 0)

          subject.sample
        end
      end

      context 'when Geo is not enabled' do
        before do
          allow(Geo::TrackingBase).to receive(:connected?).and_return(false)
        end

        it 'records no samples' do
          expect(subject.metrics[:size]).not_to receive(:set).with(labels, anything)

          subject.sample
        end

        it 'still records samples for other connections' do
          expect(subject.metrics[:size]).to receive(:set)

          subject.sample
        end
      end
    end

    context 'for Gitlab::Database::LoadBalancing::Host' do
      let(:labels) { { class: 'Gitlab::Database::LoadBalancing::Host' } }

      context 'when database load balancing is enabled' do
        let(:hosts) { %w[secondary-1 secondary-2] }
        let(:proxy) { ::Gitlab::Database::LoadBalancing::ConnectionProxy.new(hosts) }

        before do
          allow(ActiveRecord::Base).to receive(:connection).and_return(proxy)
          allow(::Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
        end

        it 'samples connection pool statistics for all hosts' do
          hosts.each do |host|
            expected_labels = a_hash_including(host: host, **labels)

            expect(subject.metrics[:size]).to receive(:set).with(expected_labels, a_value >= 1)
            expect(subject.metrics[:connections]).to receive(:set).with(expected_labels, a_value >= 0)
            expect(subject.metrics[:busy]).to receive(:set).with(expected_labels, a_value >= 0)
            expect(subject.metrics[:dead]).to receive(:set).with(expected_labels, a_value >= 0)
            expect(subject.metrics[:waiting]).to receive(:set).with(expected_labels, a_value >= 0)
          end

          subject.sample
        end
      end

      context 'when database load balancing is not enabled' do
        it 'records no samples' do
          expect(subject.metrics[:size]).not_to receive(:set).with(a_hash_including(labels), anything)

          subject.sample
        end

        it 'still records samples for other connections' do
          expect(subject.metrics[:size]).to receive(:set)

          subject.sample
        end
      end
    end
  end
end
