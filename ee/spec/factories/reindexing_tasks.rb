# frozen_string_literal: true

FactoryBot.define do
  factory :reindexing_task do
    stage { :initial }
    index_name_from { 'old_index_name' }
    index_name_to { 'new_index_name' }
  end
end
