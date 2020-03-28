# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_occurrence_pipeline, class: 'Vulnerabilities::OccurrencePipeline' do
    occurrence factory: :vulnerabilities_occurrence
    pipeline factory: :ci_pipeline
  end
end
