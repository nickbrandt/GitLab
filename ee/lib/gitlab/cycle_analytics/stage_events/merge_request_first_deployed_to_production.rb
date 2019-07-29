# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class MergeRequestFirstDeployedToProduction < SimpleStageEvent
        def self.name
          s_("CycleAnalyticsEvent|Merge request first deployed to production")
        end

        def self.identifier
          :merge_request_first_deployed_to_production
        end

        def object_type
          MergeRequest
        end

        def timestamp_projection
          mr_metrics_table[:first_deployed_to_production_at]
        end

        def apply_query_customization(query)
          inner_join(query, mr_metrics_table[:merge_request_id])
        end
      end
    end
  end
end
