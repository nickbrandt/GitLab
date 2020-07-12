# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Stages
      class ListService < BaseService
        def execute
          return forbidden unless can?(current_user, :read_group_cycle_analytics, parent)

          success(persisted_stages.presence || build_default_stages)
        end

        private

        def success(stages)
          ServiceResponse.success(payload: { stages: stages })
        end

        def persisted_stages
          scope = parent.cycle_analytics_stages
          scope = scope.by_value_stream(params[:value_stream]) if params[:value_stream]
          scope.for_list
        end
      end
    end
  end
end
