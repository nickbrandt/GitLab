# frozen_string_literal: true

FactoryBot.define do
  factory :design_action, class: 'DesignManagement::Action' do
    design
    association :version, factory: :design_version
    event { :creation }
  end
end
