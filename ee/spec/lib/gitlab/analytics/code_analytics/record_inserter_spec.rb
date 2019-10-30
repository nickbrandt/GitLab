# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Analytics::CodeAnalytics::RecordInserter do
  let_it_be(:committed_date) { Date.today }
  let_it_be(:project) { create(:project) }

  let_it_be(:user_model_path) { 'app/models/user.rb' }
  let_it_be(:user_model_spec_path) { 'spec/models/user_spec.rb' }
  let_it_be(:gemfile_path) { 'Gemfile' }
  let_it_be(:gemfile_lock_path) { 'Gemfile.lock' }

  let_it_be(:changed_files) do
    [
      user_model_path,
      user_model_spec_path,
      gemfile_path,
      gemfile_lock_path
    ]
  end

  let(:persisted_repository_files) { Analytics::CodeAnalytics::RepositoryFile.all }
  let(:persisted_repository_file_commits) { Analytics::CodeAnalytics::RepositoryFileCommit.all }

  subject { described_class.new(project: project, changed_files: changed_files, committed_date: committed_date).execute }

  before_all do
    gemfile = create(:analytics_repository_file, project: project, file_path: gemfile_path)
    user_model = create(:analytics_repository_file, project: project, file_path: user_model_path)

    create(:analytics_repository_file_commit, project: project, committed_date: committed_date, commit_count: 2, analytics_repository_file: gemfile)
    create(:analytics_repository_file_commit, project: project, committed_date: committed_date, commit_count: 1, analytics_repository_file: user_model)

    described_class.new(project: project, changed_files: changed_files, committed_date: committed_date).execute
  end

  it { expect(persisted_repository_files.count).to eq(changed_files.count) }

  it { expect(persisted_repository_file_commits.count).to eq(changed_files.count) }

  it 'inserts missing RepositoryFile records' do
    expect(persisted_repository_files.find_by(file_path: gemfile_lock_path)).to be_present
    expect(persisted_repository_files.find_by(file_path: user_model_spec_path)).to be_present
  end

  context 'verifying `commit_count`' do
    using RSpec::Parameterized::TableSyntax

    where(:repository_file_path, :expected_commit_count) do
      'app/models/user.rb'       | 2
      'spec/models/user_spec.rb' | 1
      'Gemfile'                  | 3
      'Gemfile.lock'             | 1
    end

    with_them do
      it 'matches with the expected commit count' do
        file_commit = persisted_repository_file_commits
          .joins(:analytics_repository_file)
          .where(analytics_repository_files: { file_path: repository_file_path })
          .first!

        expect(file_commit.commit_count).to eq(expected_commit_count)
      end
    end
  end
end
