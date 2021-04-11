# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsDiff do
  let(:merge_request_context_commit_diff_file) { create(:merge_request_context_commit_diff_file) }
  let(:merge_request) { merge_request_context_commit_diff_file.merge_request_context_commit.merge_request }
  let(:context_commits_diff) { merge_request.context_commits_diff }

  subject { context_commits_diff }

  describe '.commits_count' do
    it 'reports commits count' do
      expect(subject.commits_count).to be(1)
    end
  end

  describe '.raw_diffs' do
    it 'returns instance of Gitlab::Git::DiffCollection' do
      expect(subject.raw_diffs).to be_a(Gitlab::Git::DiffCollection)
    end
  end
end
