# frozen_string_literal: true

FactoryBot.define do
  factory :dast_site do
    project
    url { FFaker::Internet.uri(:https) }
  end
end
