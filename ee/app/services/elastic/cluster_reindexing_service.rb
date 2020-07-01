# frozen_string_literal: true

module Elastic
  class ClusterReindexingService
    INITIAL_INDEX_OPTIONS = { # Optimized for writes
        refresh_interval: -1, # Disable automatic refreshing
        number_of_replicas: 0,
        translog: { durability: 'async' }
    }.freeze

    def execute
      case current_task.state.to_sym
      when :initial
        initial!
      when :indexing_paused
        indexing_paused!
      when :reindexing
        reindexing!
      end
    end

    def current_task
      Elastic::ReindexingTask.current
    end

    private

    def default_index_options
      {
        refresh_interval: nil, # Change it back to the default
        number_of_replicas: Gitlab::CurrentSettings.elasticsearch_replicas,
        translog: { durability: 'request' }
      }
    end

    def initial!
      # Pause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)

      unless elastic_helper.alias_exists?
        abort_reindexing!('Your Elasticsearch index must first use aliases before you can use this feature. Please recreate your index from scratch before reindexing.')
        return false
      end

      expected_free_size = elastic_helper.index_size_bytes * 2
      if elastic_helper.cluster_free_size_bytes < expected_free_size
        abort_reindexing!("You should have at least #{expected_free_size} bytes of storage available to perform reindexing. Please increase the storage in your Elasticsearch cluster before reindexing.")
        return false
      end

      current_task.update!(state: :indexing_paused)

      true
    end

    def indexing_paused!
      # Create an index with custom settings
      index_name = elastic_helper.create_empty_index(with_alias: false, options: { settings: INITIAL_INDEX_OPTIONS })

      # Record documents count
      documents_count = elastic_helper.index_size.dig('docs', 'count')

      # Trigger reindex
      task_id = elastic_helper.reindex(to: index_name)

      current_task.update!(
        index_name_from: elastic_helper.target_index_name,
        index_name_to: index_name,
        documents_count: documents_count,
        elastic_task: task_id,
        state: :reindexing
      )

      true
    end

    def reindexing!
      task = current_task

      # Check if indexing is completed
      task_status = elastic_helper.task_status(task_id: task.elastic_task)
      return false unless task_status['completed']

      # Check if reindexing is failed
      reindexing_error = task_status.dig('error', 'type')
      if reindexing_error
        abort_reindexing!("Task #{task.elastic_task} has failed with Elasticsearch error.", additional_logs: { elasticsearch_error_type: reindexing_error })
        return false
      end

      # Refresh a new index
      elastic_helper.refresh_index(index_name: task.index_name_to)

      # Compare documents count
      old_documents_count = task.documents_count
      new_documents_count = elastic_helper.index_size(index_name: task.index_name_to).dig('docs', 'count')
      if old_documents_count != new_documents_count
        abort_reindexing!("Documents count is different, Count from new index: #{new_documents_count} Count from original index: #{old_documents_count}. This likely means something went wrong during reindexing.")
        return false
      end

      # Change index settings back
      elastic_helper.update_settings(index_name: task.index_name_to, settings: default_index_options)

      # Switch alias to a new index
      elastic_helper.switch_alias(to: task.index_name_to)

      # Unpause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)

      task.update!(state: :success)

      true
    end

    def abort_reindexing!(reason, additional_logs: {})
      error = { message: 'elasticsearch_reindex_error', error: reason, elasticsearch_task_id: current_task.elastic_task, gitlab_task_id: current_task.id, gitlab_task_state: current_task.state }
      logger.error(error.merge(additional_logs))

      current_task.update!(
        state: :failure,
        error_message: reason
      )

      # Unpause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end

    def elastic_helper
      Gitlab::Elastic::Helper.default
    end
  end
end
