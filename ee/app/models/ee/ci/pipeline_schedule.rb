# frozen_string_literal: true

module EE
  module Ci
    module PipelineSchedule
      extend ActiveSupport::Concern

      prepended do
        include UsageStatistics
        include Limitable

        self.limit_name = 'ci_pipeline_schedules'
        self.limit_scope = :project
      end
    end
  end
end
