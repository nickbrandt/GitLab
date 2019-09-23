# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

describe EE::Gitlab::Ci::Config::Entry::Needs do
  subject { described_class.new(config) }

  context 'when needs is a bridge needs' do
    context 'when upstream config is a non-empty string' do
      let(:config) { { pipeline: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a upstream configuration hash' do
          expect(subject.value).to eq(pipeline: 'some/project')
        end
      end
    end

    context 'when upstream config is not a string' do
      let(:config) { { pipeline: 123 } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to eq('bridge needs pipeline should be a string')
        end
      end
    end
  end

  context 'when needs is a complex needs' do
    let(:config) { ['test', { pipeline: 'test' }] }

    it 'test' do
      subject
    end
  end

  context 'when needs is empty' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(subject.errors.first)
          .to end_with('has to be either an array of conditions or a hash')
      end
    end
  end
end
