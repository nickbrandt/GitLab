# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CodeAnalytics::CommitWorker do
  let_it_be(:project) { create(:project, :repository) }

  subject { described_class.new }

  describe '#perform' do
    context 'when project cannot be found' do
      it 'returns false' do
        expect(subject.perform(-1, 'does_not_matter')).to be(false)
      end
    end

    context 'when commit cannot be found' do
      it 'returns false' do
        expect(subject.perform(project.id, 'unknown_commit_sha')).to be(false)
      end
    end

    it 'inserts records to the code analytics tables' do
      commit, * = project.repository.commits(nil, limit: 1)

      described_class.new.perform(project.id, commit.sha)

      expected_file_paths = commit.diffs.diff_files.map(&:new_path)
      expect(expected_file_paths).not_to be_empty
      expect(Analytics::CodeAnalytics::RepositoryFile.count).to eq(expected_file_paths.count)
      expect(Analytics::CodeAnalytics::RepositoryFileCommit.count).to eq(expected_file_paths.count)
    end
  end
end
