# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Secrets::Vault::Server do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) do
        {
          url: 'https://vault.example.com',
          auth: { name: 'jwt', path: 'jwt', data: { role: 'production' } },
          secrets: {}
        }
      end

      describe '#value' do
        it 'returns Vault server configuration' do
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
      context 'when url is not addressable' do
        let(:config) { { url: 'vault.example.com' } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'server url is blocked: only allowed schemes are http, https'
        end
      end

      context 'when url is not present' do
        let(:config) { {} }

        it 'reports error' do
          expect(entry.errors)
            .to include "server url can't be blank"
        end
      end

      context 'when there is an unknown key present' do
        let(:config) { { foo: :bar } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'server config contains unknown keys: foo'
        end
      end

      context 'when config is of incorrect type' do
        let(:config) { [] }

        it 'reports error' do
          expect(entry.errors)
            .to include 'server config should be a hash'
        end
      end

      context 'when auth is not hash' do
        let(:config) { { url: 'https://vault.example.com', auth: [] } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'server auth should be a hash'
        end
      end

      context 'when secrets is not hash' do
        let(:config) { { url: 'https://vault.example.com', secrets: [] } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'server secrets should be a hash'
        end
      end
    end
  end
end
