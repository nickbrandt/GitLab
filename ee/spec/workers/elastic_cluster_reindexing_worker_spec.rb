# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticClusterReindexingWorker do
  subject { described_class.new }

  describe '#perform' do
    using RSpec::Parameterized::TableSyntax

    where(:stage, :return_value, :scheduled_stage, :expect_schedule) do
      'initial'  |  true  | 'indexing' | true
      'indexing' |  true  | 'final'    | true
      'final'    |  false | 'final'    | true
      'final'    |  false | 'final'    | false
    end

    with_them do
      it 'schedules next stage' do
        expect_next_instance_of(Elastic::ClusterReindexingService) do |service|
          expect(service).to receive(:execute).with(stage: stage).and_return(return_value)
        end

        expect(described_class).to receive(:perform_in).with(anything, scheduled_stage)

        subject.perform(stage)
      end
    end
  end
end
