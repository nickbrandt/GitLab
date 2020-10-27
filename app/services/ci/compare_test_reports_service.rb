# frozen_string_literal: true

module Ci
  class CompareTestReportsService < CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::TestReportsComparer
    end

    def serializer_class
      TestReportsComparerSerializer
    end

    def get_report(pipeline)
      pipeline&.test_reports
    end

    def build_comparer(base_report, head_report)
      # We need to load the test failure history on the test comparer because we display
      # this on the MR widget
      super.tap do |test_reports_comparer|
        ::Gitlab::Ci::Reports::TestFailureHistory.new(failed_test_cases(test_reports_comparer), project).load!
      end
    end

    def failed_test_cases(test_reports_comparer)
      [].tap do |test_cases|
        test_reports_comparer.suite_comparers.each do |suite_comparer|
          # We're basing off the limited tests because this is what's presented on the MR widget
          # and at the same time we only want to query for a limited amount of test failures.
          limited_tests = suite_comparer.limited_tests
          test_cases.concat(limited_tests.new_failures + limited_tests.existing_failures)
        end
      end
    end
  end
end
