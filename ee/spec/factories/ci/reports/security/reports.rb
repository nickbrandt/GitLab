# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_report, class: ::Gitlab::Ci::Reports::Security::Report do
    type :sast
    commit_sha { Digest::SHA1.hexdigest(SecureRandom.hex) }

    transient do
      occurrences []
    end

    after :build do |report, evaluator|
      evaluator.occurrences.each { |o| report.add_occurrence(o) }
    end

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Report.new(type, commit_sha)
    end
  end
end
