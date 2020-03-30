# frozen_string_literal: true

require 'spec_helper'

describe DiffsEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project, current_user: user) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }

  let(:entity) do
    described_class.new(merge_request_diffs.first.diffs, request: request, merge_request: merge_request, merge_request_diffs: merge_request_diffs)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'contains needed attributes' do
      expect(subject).to include(
        :real_size, :size, :branch_name,
        :target_branch_name, :commit, :merge_request_diff,
        :start_version, :latest_diff, :latest_version_path,
        :added_lines, :removed_lines, :render_overflow_warning,
        :email_patch_path, :plain_diff_path, :diff_files,
        :merge_request_diffs
      )
    end

    context "when a commit_id is passed" do
      let(:commits) { [nil] + merge_request.commits + [nil] }
      let(:entity) do
        described_class.new(
          merge_request_diffs.first.diffs,
          request: request,
          merge_request: merge_request,
          merge_request_diffs: merge_request_diffs,
          commit: @commit
        )
      end

      subject { entity.as_json }

      context "when the passed commit is not the first or last in the group" do
        it 'includes commit references for previous and next' do
          @commit = commits.third
          check_neighbor_commits(commits, @commit)
        end
      end

      context "when the passed commit is the first in the group" do
        it 'includes commit references for nil and next' do
          @commit = commits.compact.last
          check_neighbor_commits(commits, @commit)
        end
      end

      context "when the passed commit is the last in the group" do
        it 'includes commit references for previous and nil' do
          @commit = commits.compact.first
          check_neighbor_commits(commits, @commit)
        end
      end
    end
  end

  private

  def check_neighbor_commits(commits, commit)
    index = commits.index(commit)
    prev_commit = commits[index - 1]&.id
    next_commit = commits[index + 1]&.id

    expect(subject[:commit]).to include(:prev_commit_id, :next_commit_id)
    expect(subject[:commit][:prev_commit_id]).to eq(prev_commit)
    expect(subject[:commit][:next_commit_id]).to eq(next_commit)
  end
end
