# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Secrets::Vault::Auth do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { name: 'jwt', path: 'jwt', data: { jwt: 'secret', role: 'production' } } }

      describe '#value' do
        it 'returns Vault auth configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'when there is an unknown key present' do
          let(:config) { { foo: :bar } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'auth config contains unknown keys: foo'
          end
        end

        context 'when config is of incorrect type' do
          let(:config) { [] }

          it 'reports error' do
            expect(entry.errors)
              .to include 'auth config should be a hash'
          end
        end

        context 'when data is not hash' do
          let(:config) { { data: [] } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'auth data should be a hash'
          end
        end
      end
    end
  end
end
