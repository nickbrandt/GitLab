# frozen_string_literal: true

FactoryBot.define do
  factory :group_hook do
    url { generate(:url) }
  end
end
