# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class RecordsFetcher
      FETCHER_CLASSES = {
        Issue => Gitlab::CycleAnalytics::IssueRecordsFetcher,
        MergeRequest => Gitlab::CycleAnalytics::MergeRequestRecordsFetcher
      }.freeze

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
          FETCHER_CLASSES.fetch(stage.model_to_query)
        end
      end

      def default_test_stage?
        stage.matches_with_stage_params?(Gitlab::CycleAnalytics::DefaultStages.params_for_test_stage)
      end

      def default_staging_stage?
        stage.matches_with_stage_params?(Gitlab::CycleAnalytics::DefaultStages.params_for_staging_stage)
      end
    end
  end
end
