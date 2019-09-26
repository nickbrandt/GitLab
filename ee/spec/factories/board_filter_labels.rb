# frozen_string_literal: true

FactoryBot.define do
  factory :board_label do
    association :board
    association :label
  end
end
