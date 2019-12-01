# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Config::Entry::Need do
  subject { described_class.new(config) }

  context 'when upstream is specified' do
    let(:config) { { pipeline: 'some/project' } }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'returns job needs configuration' do
        expect(subject.value).to eq(pipeline: 'some/project')
      end
    end
  end

  context 'when need is empty' do
    let(:config) { {} }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(subject.errors)
          .to include("bridge hash config can't be blank")
      end
    end
  end
end
