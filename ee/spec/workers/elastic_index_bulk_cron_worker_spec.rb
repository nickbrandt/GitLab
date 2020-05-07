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

    it 'adds the elastic_bulk_count to the done log' do
      expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
        expect(service).to receive(:execute).and_return(15)
      end
      worker = described_class.new

      worker.perform

      expect(worker.logging_extras).to eq(
        "#{ApplicationWorker::LOGGING_EXTRA_KEY}.elastic_index_bulk_cron_worker.records_count" => 15
      )
    end
  end
end
