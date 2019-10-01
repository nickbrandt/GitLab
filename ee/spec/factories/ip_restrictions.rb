# frozen_string_literal: true

FactoryBot.define do
  factory :ip_restriction do
    range { '192.168.0.0/24' }
    group
  end
end
