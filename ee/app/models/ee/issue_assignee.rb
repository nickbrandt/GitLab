# frozen_string_literal: true
module EE
  module IssueAssignee
    extend ActiveSupport::Concern

    prepended do
      after_commit :update_elasticsearch_index, on: [:create, :destroy]
    end

    def update_elasticsearch_index
      if issue.project&.use_elasticsearch?
        ::ElasticIndexerWorker.perform_async(
          :update,
          'Issue',
          issue.id,
          issue.es_id,
          changed_fields: ['assignee_ids']
        )
      end
    end
  end
end
