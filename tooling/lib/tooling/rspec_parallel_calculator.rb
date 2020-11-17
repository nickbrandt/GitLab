# frozen_string_literal: true
require_relative '../../../lib/quality/test_level'

module Tooling
  class RSpecParallelCalculator
    DEFAULT_TARGET_MINUTES = 15
    EE_PREFIX = 'ee/'

    def initialize(knapsack_report, target_minutes:, test_level: Quality::TestLevel.new)
      @knapsack_report = knapsack_report
      @target_minutes = (target_minutes || DEFAULT_TARGET_MINUTES).to_i
      @test_level = test_level
    end

    def parallel_count(project:, level:)
      @parallel_counts ||= Hash.new {|h, k| h[k] = {} }
      @parallel_counts[project][level] ||= (aggregate_duration[project][level].to_f / (target_minutes * 60)).ceil
    end

    private

    attr_reader :knapsack_report, :test_level, :target_minutes

    def aggregate_duration
      @aggregate_duration ||= aggregate_duration_per_project_level(knapsack_report)
    end

    def aggregate_duration_per_project_level(knapsack_report)
      ee_report, foss_report = knapsack_report.partition { |path, _| path.start_with?(EE_PREFIX) }

      {
        ee: aggregate_duration_per_level(ee_report),
        foss: aggregate_duration_per_level(foss_report)
      }
    end

    def aggregate_duration_per_level(report)
      report.each_with_object(Hash.new { |h, k| h[k] = 0 }) do |(file_path, duration), aggregate|
        level = test_level.level_for(file_path)
        aggregate[level] += duration
      end
    end
  end
end
