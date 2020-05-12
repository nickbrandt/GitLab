# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Secrets::Vault do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { {} }

      describe '#value' do
        it 'returns Vault provider configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when config is of incorrect type' do
      let(:config) { [] }

      it 'reports error' do
        expect(entry.errors)
          .to include 'vault config should be a hash'
      end
    end
  end

  describe '#compose!' do
    context 'when valid vault entries composed' do
      let(:config) do
        {
          vault_1: {
            url: 'https://vault_1.example.com',
            auth: { name: 'jwt', path: 'jwt', data: { role: 'production' } },
            secrets: {}
          },
          vault_2: {
            url: 'https://vault_2.example.com',
            auth: { name: 'jwt', path: 'jwt', data: { role: 'production' } },
            secrets: {}
          }
        }
      end

      before do
        entry.compose!
      end

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq(config)
        end
      end

      describe '#descendants' do
        it 'creates valid descendant nodes' do
          expect(entry.descendants).to all(be_a(Gitlab::Ci::Config::Entry::Secrets::Vault::Server))
        end
      end
    end
  end
end
