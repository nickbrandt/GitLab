# frozen_string_literal: true

class ElasticIndexerWorker
  include ApplicationWorker
  include Elasticsearch::Model::Client::ClassMethods

  sidekiq_options retry: 2
  feature_category :search

  def perform(operation, class_name, record_id, es_id, options = {})
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    klass = class_name.constantize

    case operation.to_s
    when /index|update/
      Elastic::IndexRecordService.new.execute(
        klass.find(record_id),
        operation.to_s.match?(/index/),
        options
      )
    when /delete/
      if options['es_parent']
        client.delete(
          index: klass.index_name,
          type: klass.document_type,
          id: es_id,
          routing: options['es_parent']
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

  def clear_project_data(record_id, es_id)
    remove_children_documents('project', record_id, es_id)
    IndexStatus.for_project(record_id).delete_all
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
