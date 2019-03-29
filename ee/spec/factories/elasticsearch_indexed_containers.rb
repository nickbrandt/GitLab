# frozen_string_literal: true

FactoryBot.define do
  factory :elasticsearch_indexed_namespace do
    namespace
  end

  factory :elasticsearch_indexed_project do
    project
  end
end
