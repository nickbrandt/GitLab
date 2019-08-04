# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class RecordsFetcher
      include StageQueryHelpers
      include Gitlab::CycleAnalytics::MetricsTables

      MAX_RECORDS = 50
      FINDER_CLASS_MAPPING = {
          Issue => IssuesFinder,
          MergeRequest => MergeRequestsFinder
      }.freeze

      SERIALIZER_CLASS_MAPPING = {
        Issue => AnalyticsIssueSerializer,
        MergeRequest => AnalyticsMergeRequestSerializer
      }.freeze

      delegate :subject_model, to: :stage

      def initialize(stage:, query:, params: {})
        @stage = stage
        @query = query
        @params = params
      end

      def serialized_records
        # Test and Staging stages should load Ci::Build records
        if default_test_stage? || default_staging_stage?
          BuildRecordsFetcher.new(stage, query, params).serialized_records
        else
          q = query
            .join(finder_arel_query).on(finder_arel_query[:id].eq(subject_model.arel_table[:id]))
            .order(stage.end_event.timestamp_projection.asc)
            .take(MAX_RECORDS)
          q = q.project(*projection_mapping[subject_model], round_duration_to_seconds.as('total_time'))
          execute_query(q).to_a.map do |item|
            SERIALIZER_CLASS_MAPPING.fetch(subject_model).new.represent(item)
          end
        end
      end

      # Casting ActiveRecord::Relation returned by the finder class to Arel so it can be joined with the main Arel query
      def finder_arel_query
        @finder_arel_query ||= begin
                                 ar_relation = FINDER_CLASS_MAPPING.fetch(subject_model)
                                   .new(params[:current_user], finder_params)
                                   .execute
                                 ar_relation = ar_relation.select(subject_model.arel_table[:id])
                                 ar_relation.arel.as('finder_results')
                               end
      end

      private

      attr_reader :stage, :query, :params

      def projection_mapping
        {
          Issue => [
            issue_table[:title],
            issue_table[:iid],
            issue_table[:id],
            issue_table[:created_at],
            issue_table[:author_id],
            projects_table[:name],
            routes_table[:path]
          ],
          MergeRequest => [
            mr_table[:title],
            mr_table[:iid],
            mr_table[:id],
            mr_table[:created_at],
            mr_table[:state],
            mr_table[:author_id],
            projects_table[:name],
            routes_table[:path]
          ]
        }
      end

      def finder_params
        {
          Project => { project_id: stage.parent.id },
          Group => { group_id: stage.parent.id, include_subgroups: true }
        }.fetch(stage.parent.class)
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
