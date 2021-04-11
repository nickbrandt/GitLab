# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContextCommitsDiffEntity do
  let(:merge_request_context_commit_diff_file) { create(:merge_request_context_commit_diff_file) }
  let(:merge_request) { merge_request_context_commit_diff_file.merge_request_context_commit.merge_request }
  let(:context_commits_diff) { merge_request.context_commits_diff }

  context 'as json' do
    describe '.diff_files' do
      it 'returns diff files metadata' do
        payload = ContextCommitsDiffEntity.represent(context_commits_diff).as_json

        expect(payload[:commits_count]).to eq(1)
      end
    end
  end
end
