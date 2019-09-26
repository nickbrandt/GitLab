# frozen_string_literal: true

FactoryBot.define do
  factory :geo_node_namespace_link do
    geo_node
    namespace
  end
end
