# frozen_string_literal: true

require 'spec_helper'

describe ElasticMetricsUpdateWorker do
  include ExclusiveLeaseHelpers

  describe '.perform' do
    it 'executes the service under an exclusive lease' do
      expect_to_obtain_exclusive_lease('elastic_metrics_update_worker')

      expect_next_instance_of(::Elastic::MetricsUpdateService) do |service|
        expect(service).to receive(:execute)
      end

      described_class.new.perform
    end
  end
end
