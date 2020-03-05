# frozen_string_literal: true

FactoryBot.define do
  factory :requirement do
    project
    author
    title { generate(:title) }
    title_html { "<h2>#{title}</h2>" }
  end
end
