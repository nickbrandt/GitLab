# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

require 'raven'

RSpec.describe Gitlab::ErrorTracking::Processor::SidekiqProcessor do
  describe '.filter_arguments' do
    it 'returns a lazy enumerator' do
      filtered = described_class.filter_arguments([1, 'string'], 'TestWorker')

      expect(filtered).to be_a(Enumerator::Lazy)
      expect(filtered.to_a).to eq([1, described_class::FILTERED_STRING])
    end

    context 'arguments filtering' do
      using RSpec::Parameterized::TableSyntax

      where(:klass, :expected) do
        'UnknownWorker' | [1, described_class::FILTERED_STRING, described_class::FILTERED_STRING, described_class::FILTERED_STRING]
        'NoPermittedArguments' | [1, described_class::FILTERED_STRING, described_class::FILTERED_STRING, described_class::FILTERED_STRING]
        'OnePermittedArgument' | [1, 'string', described_class::FILTERED_STRING, described_class::FILTERED_STRING]
        'AllPermittedArguments' | [1, 'string', [1, 2], { a: 1 }]
      end

      with_them do
        before do
          permitted_arguments = Hash.new(Set.new).merge(
            'NoPermittedArguments' => [],
            'OnePermittedArgument' => [1],
            'AllPermittedArguments' => [0, 1, 2, 3]
          ).transform_values!(&:to_set)

          stub_const("#{described_class}::PERMITTED_ARGUMENTS", permitted_arguments)
        end

        it do
          expect(described_class.filter_arguments([1, 'string', [1, 2], { a: 1 }], klass).to_a)
            .to eq(expected)
        end
      end
    end
  end

  describe '#process' do
    context 'when there is Sidekiq data' do
      shared_examples 'Sidekiq arguments' do |args_in_job_hash: true|
        let(:path) { [:extra, :sidekiq, args_in_job_hash ? :job : nil, 'args'].compact }
        let(:args) { [1, 'string', { a: 1 }, [1, 2]] }

        it 'only allows numeric arguments for an unknown worker' do
          value = { 'args' => args, 'class' => 'UnknownWorker' }

          value = { job: value } if args_in_job_hash

          expect(subject.process(extra_sidekiq(value)).dig(*path))
            .to eq([1, described_class::FILTERED_STRING, described_class::FILTERED_STRING, described_class::FILTERED_STRING])
        end

        it 'allows all argument types for a permitted worker' do
          value = { 'args' => args, 'class' => 'PostReceive' }

          value = { job: value } if args_in_job_hash

          expect(subject.process(extra_sidekiq(value)).dig(*path))
            .to eq(args)
        end
      end

      context 'when processing via the default error handler' do
        include_examples 'Sidekiq arguments', args_in_job_hash: true
      end

      context 'when processing via Gitlab::ErrorTracking' do
        include_examples 'Sidekiq arguments', args_in_job_hash: false
      end

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
