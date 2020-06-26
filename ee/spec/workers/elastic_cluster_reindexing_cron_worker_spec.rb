# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticClusterReindexingCronWorker do
  subject { described_class.new }

  describe '#perform' do
    before do
      allow(ReindexingTask).to receive(:current).and_return(build(:reindexing_task))
    end

    it 'schedules current stage' do
      expect_next_instance_of(Elastic::ClusterReindexingService) do |service|
        expect(service).to receive(:execute).with(stage: 'initial')
      end

      subject.perform
    end
  end
end
