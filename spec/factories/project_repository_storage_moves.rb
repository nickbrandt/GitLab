# frozen_string_literal: true

FactoryBot.define do
  factory :project_repository_storage_move, class: 'ProjectRepositoryStorageMove' do
    project

    source_storage_name { 'default' }
    destination_storage_name { 'default' }
  end
end
