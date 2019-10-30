# frozen_string_literal: true

require 'spec_helper'

describe Analytics::ProductivityCalculator do
  subject { described_class.new(merge_request) }

  let(:merge_request) { create(:merge_request_with_diff_notes, :merged, :with_diffs, created_at: 31.days.ago) }

  describe '#productivity_data' do
    it 'calculates productivity data' do
      expected_data = {
        first_comment_at: merge_request.notes.order(created_at: :asc).first.created_at,
        first_commit_at: merge_request.first_commit.authored_date,
        last_commit_at: merge_request.merge_request_diff.last_commit.committed_date,
        commits_count: merge_request.commits_count,
        diff_size: merge_request.merge_request_diff.lines_count,
        modified_paths_size: merge_request.modified_paths.size
      }

      expect(subject.productivity_data).to eq(expected_data)
    end
  end
end
