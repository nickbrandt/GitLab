# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::Ci::Config::Entry::Need do
  subject(:need) { described_class.new(config) }

  context 'when job is specified' do
    let(:config) { 'job_name' }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'returns job needs configuration' do
        expect(need.value).to eq('job_name')
      end
    end
  end

  context 'when job is specified as symbol' do
    let(:config) { :job_name }

    describe '#valid?' do
      it { is_expected.to be_valid }
    end

    describe '#value' do
      it 'returns job needs configuration' do
        expect(need.value).to eq('job_name')
      end
    end
  end

  context 'when need is empty' do
    let(:config) { '' }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        expect(need.errors.first)
          .to end_with("pipeline config can't be blank")
      end
    end
  end

  context 'when need is not a string' do
    let(:config) { 123 }

    describe '#valid?' do
      it { is_expected.not_to be_valid }
    end

    describe '#errors' do
      it 'is returns an error about an empty config' do
        error_message = Gitlab.ee? ? 'has to be a string, symbol or hash' : 'has to be a string or symbol'

        expect(need.errors.first)
          .to end_with(error_message)
      end
    end
  end
end
