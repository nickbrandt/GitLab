# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_aggregated_reports, class: ::Gitlab::Ci::Reports::Security::AggregatedReport do
    reports { FactoryBot.build_list(:ci_reports_security_report, 1) }
    occurrences { FactoryBot.build_list(:ci_reports_security_occurrence, 1) }

    initialize_with do
      ::Gitlab::Ci::Reports::Security::AggregatedReport.new(reports, occurrences)
    end
  end
end
