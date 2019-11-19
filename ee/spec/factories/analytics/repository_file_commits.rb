# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_repository_file_commit, class: 'Analytics::CodeAnalytics::RepositoryFileCommit' do
    commit_count { 5 }
    committed_date { Date.today }
    project
    analytics_repository_file
  end
end
