# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_repository_file, class: 'Analytics::CodeAnalytics::RepositoryFile' do
    project
    file_path { 'app/db/migrate/file.rb' }
  end
end
