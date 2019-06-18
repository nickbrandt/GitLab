# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require 'timecop'

describe Atlassian::Jwt do
  describe '#create_query_string_hash' do
    using RSpec::Parameterized::TableSyntax

    let(:base_uri) { 'https://example.com/-/jira_connect' }

    where(:path, :method, :expected_hash) do
      '/events/uninstalled'  | 'POST' | '57d5306d4c520456ebb58ac802779232a941e583589354b8a31aa949cdd4c9ae'
      '/events/uninstalled/' | 'post' | '57d5306d4c520456ebb58ac802779232a941e583589354b8a31aa949cdd4c9ae'
      '/configuration'       | 'GET'  | 'be30d9dc39ca6a6543a0b05a253ed9aa36d282311af4cecad54b487dffa62769'
      '/'                    | 'PUT'  | 'c88c7735138a8806c60f95f0d3e133d1d3d313e2a9d590abbb5f898dabad7b62'
      ''                     | 'PUT'  | 'c88c7735138a8806c60f95f0d3e133d1d3d313e2a9d590abbb5f898dabad7b62'
    end

    with_them do
      it 'generates correct hash with base URI' do
        hash = subject.create_query_string_hash(method, base_uri + path, base_uri: base_uri)

        expect(hash).to eq(expected_hash)
      end

      it 'generates correct hash with base URI already removed' do
        hash = subject.create_query_string_hash(method, path)

        expect(hash).to eq(expected_hash)
      end
    end
  end

  describe '#build_claims' do
    let(:other_options) { {} }

    subject { described_class.build_claims(issuer: 'gitlab', method: 'post', uri: '/rest/devinfo/0.10/bulk', **other_options) }

    it 'sets the iss claim' do
      expect(subject[:iss]).to eq('gitlab')
    end

    it 'sets qsh claim based on HTTP method and path' do
      expect(subject[:qsh]).to eq(described_class.create_query_string_hash('post', '/rest/devinfo/0.10/bulk'))
    end

    describe 'iat claim' do
      it 'sets default value to current time' do
        Timecop.freeze do
          expect(subject[:iat]).to eq(Time.now.to_i)
        end
      end

      context do
        let(:issued_time) { Time.now + 30.days }
        let(:other_options) { { issued_at: issued_time.to_i } }

        it 'allows overriding with option' do
          expect(subject[:iat]).to eq(issued_time.to_i)
        end
      end
    end

    describe 'exp claim' do
      it 'sets default value to 1 minute from now' do
        Timecop.freeze do
          expect(subject[:exp]).to eq(Time.now.to_i + 60)
        end
      end

      context do
        let(:expiry_time) { Time.now + 30.days }
        let(:other_options) { { expires: expiry_time.to_i } }

        it 'allows overriding with option' do
          expect(subject[:exp]).to eq(expiry_time.to_i)
        end
      end
    end

    describe 'other claims' do
      let(:other_options) { { other_claims: { some_claim: 'some_claim_value' } } }

      it 'allows adding of additional claims' do
        expect(subject[:some_claim]).to eq('some_claim_value')
      end
    end
  end
end
