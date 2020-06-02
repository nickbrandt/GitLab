# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require 'raven'

RSpec.describe Gitlab::ErrorTracking::Processor::SidekiqProcessor do
  describe '#process' do
    context 'when there is Sidekiq data' do
      it 'removes a jobstr field if present' do
        value = {
          job: { 'args' => [1] },
          jobstr: { 'args' => [1] }.to_json
        }

        expect(subject.process(extra_sidekiq(value)))
          .to eq(extra_sidekiq(value.except(:jobstr)))
      end

      it 'does nothing with no jobstr' do
        value = { job: { 'args' => [1] } }

        expect(subject.process(extra_sidekiq(value)))
          .to eq(extra_sidekiq(value))
      end
    end

    context 'when there is no Sidekiq data' do
      it 'does nothing' do
        value = {
          request: {
            method: 'POST',
            data: { 'key' => 'value' }
          }
        }

        expect(subject.process(value)).to eq(value)
      end
    end

    def extra_sidekiq(hash)
      { extra: { sidekiq: hash } }
    end
  end
end
