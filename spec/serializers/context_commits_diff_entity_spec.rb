# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsDiffEntity do
  let(:mrcc1) { create(:merge_request_context_commit, sha: "cfe32cf61b73a0d5e9f13e774abde7ff789b1660") }
  let(:mrcc2) { create(:merge_request_context_commit, sha: "ae73cb07c9eeaf35924a10f713b364d32b2dd34f") }
  let(:merge_request) { create(:merge_request) { |merge_request| merge_request.merge_request_context_commits << [mrcc1, mrcc2] } }

  context 'as json' do
    subject { ContextCommitsDiffEntity.represent(merge_request.context_commits_diff).as_json }

    it 'exposes commits_count' do
      expect(subject[:commits_count]).to eq(2)
    end

    it 'exposes showing_context_commits_diff' do
      expect(subject).to have_key(:showing_context_commits_diff)
    end

    it 'exposes diffs_path' do
      expect(subject[:diffs_path]).to match(/\/-\/merge_requests\/\d\/diffs\?only_context_commits=true$/)
    end
  end
end
