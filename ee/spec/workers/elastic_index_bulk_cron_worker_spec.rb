# frozen_string_literal: true

require 'spec_helper'

describe ElasticIndexBulkCronWorker do
  include ExclusiveLeaseHelpers
  describe '.perform' do
    it 'executes the service under an exclusive lease' do
      expect_to_obtain_exclusive_lease('elastic_index_bulk_cron_worker')

      expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
        expect(service).to receive(:execute)
      end

      described_class.new.perform
    end
  end
end
