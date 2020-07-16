# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerability_statistic, class: 'Vulnerabilities::Statistic' do
    project
    letter_grade { :a }
  end
end
