# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_report, class: '::Gitlab::Ci::Reports::Security::Report' do
    type { :sast }
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }
    created_at { 2.weeks.ago }

    transient do
      occurrences { [] }
      scanners { [] }
      identifiers { [] }
    end

    after :build do |report, evaluator|
      evaluator.scanners.each { |s| report.add_scanner(s) }
      evaluator.identifiers.each { |id| report.add_identifier(id) }
      evaluator.occurrences.each { |o| report.add_occurrence(o) }
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Report.new(type, commit_sha, created_at)
    end
  end
end
