# frozen_string_literal: true
class ElasticIndexerWorker
  include ApplicationWorker
  include Elasticsearch::Model::Client::ClassMethods

  sidekiq_options retry: 2

  ISSUE_TRACKED_FIELDS = %w(assignee_ids author_id confidential).freeze

  def perform(operation, class_name, record_id, es_id, options = {})
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    klass = class_name.constantize

    case operation.to_s
    when /index|update/
      record = klass.find(record_id)
      record.__elasticsearch__.client = client

      import(operation, record, klass)

      initial_index_project(record) if klass == Project && operation.to_s.match?(/index/)

      update_issue_notes(record, options["changed_fields"]) if klass == Issue
    when /delete/
      if klass.nested?
        client.delete(
          index: klass.index_name,
          type: klass.document_type,
          id: es_id,
          routing: options["es_parent"]
        )
      else
        clear_project_data(record_id, es_id) if klass == Project
        client.delete index: klass.index_name, type: klass.document_type, id: es_id
      end
    end
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

  def clear_project_data(record_id, es_id)
    remove_children_documents('project', record_id, es_id)
    IndexStatus.for_project(record_id).delete_all
  end

  def initial_index_project(project)
    {
      Issue        => project.issues,
      MergeRequest => project.merge_requests,
      Snippet      => project.snippets,
      Note         => project.notes.searchable,
      Milestone    => project.milestones
    }.each do |klass, objects|
      objects.find_each { |object| import(:index, object, klass) }
    end

    # Finally, index blobs/commits/wikis
    ElasticCommitIndexerWorker.perform_async(project.id)
  end

  def import(operation, record, klass)
    if klass.nested?
      record.__elasticsearch__.__send__ "#{operation}_document", routing: record.es_parent # rubocop:disable GitlabSecurity/PublicSend
    else
      record.__elasticsearch__.__send__ "#{operation}_document" # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  def remove_documents_by_project_id(record_id)
    client.delete_by_query({
      index: Project.__elasticsearch__.index_name,
      body: {
        query: {
          term: { "project_id" => record_id }
        }
      }
    })
  end

  def remove_children_documents(parent_type, parent_record_id, parent_es_id)
    client.delete_by_query({
      index: Project.__elasticsearch__.index_name,
      routing: parent_es_id,
      body: {
        query: {
          has_parent: {
            parent_type: parent_type,
            query: {
              term: { id: parent_record_id }
            }
          }
        }
      }
    })
  end
end
