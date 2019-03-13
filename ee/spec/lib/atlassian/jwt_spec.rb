# frozen_string_literal: true

require 'spec_helper'

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
        hash = subject.create_query_string_hash(method, base_uri + path, base_uri)

        expect(hash).to eq(expected_hash)
      end

      it 'generates correct hash with base URI already removed' do
        hash = subject.create_query_string_hash(method, path)

        expect(hash).to eq(expected_hash)
      end
    end
  end
end
