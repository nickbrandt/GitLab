# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DataFilter
      def initialize(stage:, params: {})
        @stage = stage
      end

      def apply(query)
        filter_by_parent_model(query)
      end

      private

      attr_reader :stage

      def filter_by_parent_model(query)
        if stage.parent.is_a?(Project)
          if stage.model_to_query.eql?(Issue)
            query.where(Issue.arel_table[:project_id].eq(stage.parent.id))
          elsif stage.model_to_query.eql?(MergeRequest)
            query.where(MergeRequest.arel_table[:target_project_id].eq(stage.parent.id))
          else
            raise 'OMG'
          end
        else
          raise 'wtf'
        end
      end
    end
  end
end
