# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Samplers::GlobalSearchSampler do
  subject { described_class.new(60.seconds) }

  describe '#sample' do
    it 'invokes the Elastic::MetricsUpdateService' do
      expect_next_instance_of(::Elastic::MetricsUpdateService) do |service|
        expect(service).to receive(:execute)
      end

      subject.sample
    end
  end
end
