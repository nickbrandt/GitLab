# frozen_string_literal: true

module Elastic
  class IndexRecordService
    include Elasticsearch::Model::Client::ClassMethods

    ISSUE_TRACKED_FIELDS = %w(assignee_ids author_id confidential).freeze

    # @param indexing [Boolean] determines whether operation is "indexing" or "updating"
    def execute(record, indexing, options = {})
      return true unless record.use_elasticsearch?

      record.__elasticsearch__.client = client

      import(record, record.class.nested?, indexing)

      initial_index_project(record) if record.class == Project && indexing

      update_issue_notes(record, options["changed_fields"]) if record.class == Issue
    rescue Elasticsearch::Transport::Transport::Errors::NotFound, ActiveRecord::RecordNotFound
      # These errors can happen in several cases, including:
      # - A record is updated, then removed before the update is handled
      # - Indexing is enabled, but not every item has been indexed yet - updating
      #   and deleting the un-indexed records will raise exception
      #
      # We can ignore these.
      true
    end

    private

    def update_issue_notes(record, changed_fields)
      if changed_fields && (changed_fields & ISSUE_TRACKED_FIELDS).any?
        Note.es_import query: -> { where(noteable: record) }
      end
    end

    def initial_index_project(project)
      # Enqueue the repository indexing jobs immediately so they run in parallel
      # One for the project repository, one for the wiki repository
      ElasticCommitIndexerWorker.perform_async(project.id)
      ElasticCommitIndexerWorker.perform_async(project.id, nil, nil, true)

      project.each_indexed_association do |klass, objects|
        objects.es_import
      end
    end

    def import(record, nested, indexing)
      operation = indexing ? 'index_document' : 'update_document'

      if nested
        record.__elasticsearch__.__send__ operation, routing: record.es_parent # rubocop:disable GitlabSecurity/PublicSend
      else
        record.__elasticsearch__.__send__ operation # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
