# frozen_string_literal: true

require 'generator_helper'

RSpec.describe Gitlab::UsageMetricDefinitionGenerator do
  describe 'Running generator' do
    let(:key_path) { 'counter.category.event' }
    let(:dir) { '7d' }
    let(:options) { [key_path, '--dir', dir, '--pretend'] }

    subject { described_class.start(options) }

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    context 'with a missing directory' do
      let(:options) { [key_path, '--pretend'] }

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'with an invalid directory' do
      let(:dir) { '8d' }

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'with an already existing metric with the same key_path' do
      before do
        allow(Gitlab::Usage::MetricDefinition).to receive(:definitions).and_return(Hash[key_path, 'definition'])
      end

      it 'raises an error' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
