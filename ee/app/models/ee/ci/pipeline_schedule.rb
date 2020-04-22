# frozen_string_literal: true

module EE
  module Ci
    module PipelineSchedule
      extend ActiveSupport::Concern

      prepended do
        include UsageStatistics
      end
    end
  end
end
