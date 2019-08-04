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
            .join(join_finder_ar_query)
            .order(stage.end_event.timestamp_projection.asc)
            .take(MAX_RECORDS)
          q = q.project(*projection_mapping[stage.model_to_query], round_duration_to_seconds.as('total_time'))
          execute_query(q).to_a.map do |item|
            SERIALIZER_CLASS_MAPPING.fetch(subject_model).new.represent(item)
          end
        end
      end

      # INNER JOIN IssuesFinder and MergeRequestsFinder ActiveRecord::Relation with the main Arel query in order to load records in scope of the current user.
      def join_finder_ar_query
        ar_relation = FINDER_CLASS_MAPPING.fetch(subject_model)
          .new(params[:current_user], finder_params)
          .execute
        ar_relation = ar_relation.select(subject_model.arel_table[:id])

        Arel.sql("INNER JOIN (#{ar_relation.to_sql}) AS records_finder_results on records_finder_results.id = #{subject_model.arel_table.table_name}.id")
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

      def subject_model
        stage.model_to_query
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
