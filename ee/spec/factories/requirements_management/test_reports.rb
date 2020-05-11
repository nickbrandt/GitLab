# frozen_string_literal: true

FactoryBot.define do
  factory :test_report, class: 'RequirementsManagement::TestReport' do
    author
    requirement
    pipeline factory: :ci_pipeline
    state { :passed }
  end
end
