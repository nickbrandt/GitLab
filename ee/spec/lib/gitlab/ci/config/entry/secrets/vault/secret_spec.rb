# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Secrets::Vault::Secret do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) do
        {
          engine: {
            name: 'kv-v2',
            path: 'kv-v2'
          },
          path: 'production/db',
          fields: %w(username password),
          strategy: 'read'
        }
      end

      describe '#value' do
        it 'returns Vault secret configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end
  end

  context 'when entry value is not correct' do
    describe '#errors' do
      context 'when there is an unknown key present' do
        let(:config) { { foo: :bar } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret config contains unknown keys: foo'
        end
      end

      context 'when path is not present' do
        let(:config) { {} }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret path can\'t be blank'
        end
      end

      context 'when fields are not present' do
        let(:config) { {} }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret fields can\'t be blank'
        end
      end

      context 'when fields are not a list' do
        let(:config) { { fields: {} } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret fields should be an array of strings'
        end
      end

      context 'when engine is not a hash' do
        let(:config) { { engine: [] } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret engine should be a hash'
        end
      end

      context 'when strategy is not allowed value' do
        let(:config) { { strategy: 'write' } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret strategy unknown value: write'
        end
      end
    end
  end
end
