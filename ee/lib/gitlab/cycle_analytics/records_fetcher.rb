# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class RecordsFetcher
      def initialize(stage:, query:)
        @stage = stage
        @query = query
      end

      def serialized_records
        fetcher_class.new(stage, query).serialized_records
      end

      private

      attr_reader :stage, :query

      def fetcher_class
        # Test and Staging stages are loading Ci::Build records
        if default_test_stage? || default_staging_stage?
          BuildRecordsFetcher
        else
          Gitlab::CycleAnalytics.const_get("#{stage.model_to_query}RecordsFetcher")
        end
      end

      def default_test_stage?
        test_stage = Gitlab::CycleAnalytics::DefaultStages.params_for_test_stage

        stage.default_stage? &&
          stage.start_event_identifier == test_stage[:start_event_identifier] &&
          stage.end_event_identifier == test_stage[:end_event_identifier]
      end

      def default_staging_stage?
        staging_stage = Gitlab::CycleAnalytics::DefaultStages.params_for_staging_stage

        stage.default_stage? &&
          stage.start_event_identifier == staging_stage[:start_event_identifier] &&
          stage.end_event_identifier == staging_stage[:end_event_identifier]
      end
    end
  end
end
