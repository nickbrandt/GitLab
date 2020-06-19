# frozen_string_literal: true

require 'spec_helper'

describe Ci::BuildMetadata do
  describe 'validations' do
    let(:metadata) { build(:ci_build).metadata }

    context 'when attributes are valid' do
      it 'returns no errors' do
        metadata.secrets = {
          DATABASE_PASSWORD: {
            vault: {
              engine: { name: 'kv-v2', path: 'kv-v2' },
              path: 'production/db',
              field: 'password'
            }
          }
        }

        expect(metadata).to be_valid
      end
    end

    context 'when data is invalid' do
      it 'returns errors' do
        metadata.secrets = { DATABASE_PASSWORD: { vault: {} } }

        aggregate_failures do
          expect(metadata).to be_invalid
          expect(metadata.errors.full_messages).to eq(["Secrets must be a valid json schema"])
        end
      end
    end
  end
end
