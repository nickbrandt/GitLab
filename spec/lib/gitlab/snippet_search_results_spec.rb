# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SnippetSearchResults do
  include SearchHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:snippet) { create(:snippet, author: user, content: 'foo', file_name: 'foo') }
  let_it_be(:secret_snippet) { create(:personal_snippet, :secret, author: user, content: 'foo', file_name: 'foo') }
  let_it_be(:other_secret_snippet) { create(:personal_snippet, :secret, content: 'foo', file_name: 'foo') }

  subject { described_class.new(user, 'foo') }

  describe '#snippet_titles_count' do
    it 'returns the amount of matched snippet titles' do
      expect(subject.limited_snippet_titles_count).to eq(1)
    end
  end

  describe '#snippet_blobs_count' do
    it 'returns the amount of matched snippet blobs' do
      expect(subject.limited_snippet_blobs_count).to eq(1)
    end
  end

  describe '#formatted_count' do
    using RSpec::Parameterized::TableSyntax

    where(:scope, :count_method, :expected) do
      'snippet_titles' | :limited_snippet_titles_count   | max_limited_count
      'snippet_blobs'  | :limited_snippet_blobs_count    | max_limited_count
      'projects'       | :limited_projects_count         | max_limited_count
      'unknown'        | nil                             | nil
    end

    with_them do
      it 'returns the expected formatted count' do
        expect(subject).to receive(count_method).and_return(1234) if count_method
        expect(subject.formatted_count(scope)).to eq(expected)
      end
    end
  end
end
