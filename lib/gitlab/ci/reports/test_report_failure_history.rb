# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class TestReportFailureHistory
        include Gitlab::Utils::StrongMemoize

        def initialize(report, project)
          @report = report
          @project = project
        end

        def load!
          return unless Feature.enabled?(:test_failure_history, project)

          recent_failures_count.each do |key_hash, count|
            failed_test_cases[key_hash].set_recent_failures(count, project.default_branch_or_master)
          end
        end

        private

        attr_reader :report, :project

        def recent_failures_count
          ::Ci::TestCaseFailure.recent_failures_count(
            project: project,
            test_case_keys: failed_test_cases.keys
          )
        end

        def failed_test_cases
          strong_memoize(:failed_test_cases) do
            report.failed_test_cases
          end
        end
      end
    end
  end
end
