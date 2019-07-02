# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Elastic::SnippetSearchResults, :elastic do
  let(:snippet) { create(:snippet, content: 'foo', file_name: 'foo') }
  let(:results) { described_class.new(snippet.author, 'foo') }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    perform_enqueued_jobs { snippet }
    Snippet.__elasticsearch__.refresh_index!
  end

  describe '#snippet_titles_count' do
    it 'returns the amount of matched snippet titles' do
      expect(results.snippet_titles_count).to eq(1)
    end
  end

  describe '#snippet_blobs_count' do
    it 'returns the amount of matched snippet blobs' do
      expect(results.snippet_blobs_count).to eq(1)
    end
  end

  context 'when user is not author' do
    let(:results) { described_class.new(create(:user), 'foo') }

    it 'returns nothing' do
      expect(results.snippet_titles_count).to eq(0)
      expect(results.snippet_blobs_count).to eq(0)
    end
  end

  context 'when user is nil' do
    let(:results) { described_class.new(nil, 'foo') }

    it 'returns nothing' do
      expect(results.snippet_titles_count).to eq(0)
      expect(results.snippet_blobs_count).to eq(0)
    end

    context 'when snippet is public' do
      let(:snippet) { create(:snippet, :public, content: 'foo', file_name: 'foo') }

      it 'returns public snippet' do
        expect(results.snippet_titles_count).to eq(1)
        expect(results.snippet_blobs_count).to eq(1)
      end
    end
  end
end
