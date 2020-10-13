# frozen_string_literal: true

FactoryBot.define do
  factory :package_event, class: 'Packages::Event' do
    event_type { :push_package }
    event_scope { :maven }
    originator_type { :guest }
    originator { nil }
  end
end
