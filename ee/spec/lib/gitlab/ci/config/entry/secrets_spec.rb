# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Secrets do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { vault: {} } }

      describe '#value' do
        it 'returns secrets configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when vault attribute is of incorrect type' do
      let(:config) { { vault: [] } }

      it 'reports error' do
        expect(entry.errors)
          .to include 'secrets vault should be a hash'
      end
    end

    context 'when there is an unknown key present' do
      let(:config) { { foo: {} } }

      it 'reports error' do
        expect(entry.errors)
          .to include 'secrets config contains unknown keys: foo'
      end
    end
  end
end
