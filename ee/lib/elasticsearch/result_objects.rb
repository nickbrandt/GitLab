# frozen_string_literal: true

module Elasticsearch
  module ResultObjects
    # Here we refine our models to learn how to load from Elasticsearch without hitting the database
    # In order to use these methods in another class you first have to `using Elasticsearch::ResultObjects`
    # and you can then use the model objects directly

    ES_ATTRIBUTES = %i(join_field type).freeze

    refine ::Project.singleton_class do
      def load_from_elasticsearch(es_response, current_user: nil)
        es_response.results.response.map(&:_source).then do |projects|
          projects.map do |project|
            ::Elasticsearch::LiteProject.new(project)
          end
        end
      end
    end

    refine ::Issue.singleton_class do
      def load_from_elasticsearch(es_response, current_user:)
        es_response.results.response.map(&:_source).then do |issues|
          projects = ::ProjectsFinder.new(
            current_user: current_user,
            project_ids_relation: issues.map(&:project_id)
          ).execute.index_by(&:id)

          issues.map do |issue|
            issue[:project] = projects[issue.delete(:project_id)]
            issue[:assignee_ids] = issue.delete(:assignee_id)
            issue.except!(*ES_ATTRIBUTES)

            new(issue)
          end
        end
      end
    end

    refine ::MergeRequest.singleton_class do
      def load_from_elasticsearch(es_response, current_user:)
        es_response.results.response.map(&:_source).then do |merge_requests|
          # rubocop: disable CodeReuse/ActiveRecord
          projects = ::ProjectsFinder.new(
            current_user: current_user,
            project_ids_relation: merge_requests.map(&:target_project_id)
          ).execute.includes(:route, namespace: [:route]).index_by(&:id)
          # rubocop: enable CodeReuse/ActiveRecord

          merge_requests.map do |merge_request|
            merge_request[:target_project] = projects[merge_request.delete(:target_project_id)]
            merge_request.except!(*ES_ATTRIBUTES)

            new(merge_request)
          end
        end
      end
    end

    refine ::Milestone.singleton_class do
      def load_from_elasticsearch(es_response, current_user:)
        es_response.results.response.map(&:_source).then do |milestones|
          projects = ::ProjectsFinder.new(
            current_user: current_user,
            project_ids_relation: milestones.map(&:project_id)
          ).execute.index_by(&:id)

          milestones.map do |milestone|
            milestone[:project] = projects[milestone.delete(:project_id)]
            milestone.except!(*ES_ATTRIBUTES)

            new(milestone)
          end
        end
      end
    end
  end
end
