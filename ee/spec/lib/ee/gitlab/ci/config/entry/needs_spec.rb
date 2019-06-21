# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

describe EE::Gitlab::Ci::Config::Entry::Needs do
  subject { described_class.new(config) }

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

  context 'when upstream config an empty string' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(subject.errors.first)
          .to eq("needs config can't be blank")
      end
    end
  end

  context 'when upstream configuration is not valid' do
    context 'when branch is not provided' do
      let(:config) { { pipeline: 123 } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to eq('needs pipeline should be a string')
        end
      end
    end
  end
end
