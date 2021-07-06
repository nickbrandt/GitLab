# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe EE::Gitlab::Ci::Config::Entry::Status do
  subject { described_class.new(config) }

  context 'when the config is a string' do
    let(:config) { 'some/project' }

    it { is_expected.to be_valid }

    describe '#value' do
      it 'returns the configuration' do
        expect(subject.value).to eq(project: 'some/project')
      end
    end

    context 'when the config is empty' do
      let(:config) { '' }

      it { is_expected.not_to be_valid }
    end
  end

  context 'when the config is a hash' do
    let(:config) { { project: 'some/project' } }

    it { is_expected.not_to be_valid }

    it 'returns an error' do
      expect(subject.errors.first).to eq('status config should be a string')
    end
  end
end
