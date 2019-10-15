# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CodeAnalytics::RepositoryFileCommit do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:analytics_repository_file) }

  describe '.top_files' do
    let_it_be(:project) { create(:project) }

    subject { described_class.top_files(project: project, from: 10.days.ago, to: Date.today) }

    context 'when no records matching the query' do
      it 'returns empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'returns file with the commit count' do
      let(:file) { create(:analytics_repository_file, project: project) }
      let!(:file_commit1) { create(:analytics_repository_file_commit, { project: project, analytics_repository_file: file, committed_date: 1.day.ago, commit_count: 2 }) }
      let!(:file_commit2) { create(:analytics_repository_file_commit, { project: project, analytics_repository_file: file, committed_date: 2.days.ago, commit_count: 2 }) }

      it { expect(subject[[file.id, file.file_path]]).to eq(4) }
    end

    context 'when the `file_count` is higher than allowed' do
      it 'raises error' do
        max_files = Analytics::CodeAnalytics::RepositoryFileCommit::MAX_FILE_COUNT

        expect do
          described_class.top_files(project: project, from: 10.days.ago, to: Date.today, file_count: max_files + 1)
        end.to raise_error(Analytics::CodeAnalytics::RepositoryFileCommit::TopFilesLimitError)
      end
    end
  end
end
