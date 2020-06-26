# frozen_string_literal: true

module Elastic
  class ClusterReindexingService
    INDEX_OPTIONS = {
        refresh_interval: -1, # Disable automatic refreshing
        number_of_replicas: 0,
        translog: { durability: 'async' }
    }.freeze

    def execute(stage: :initial)
      case stage.to_sym
      when :initial
        preflight_check!

        initial_stage!
      when :indexing
        check_stage_order!(allowed_stages: [:initial], current_stage: stage)

        indexing_stage!
      when :final
        check_stage_order!(allowed_stages: [:indexing, :final], current_stage: stage)

        final_stage!
      end
    end

    def current_task
      ReindexingTask.current
    end

    private

    def check_stage_order!(allowed_stages:, current_stage:)
      return if allowed_stages.map(&:to_s).include?(current_task&.stage)

      raise StandardError, "#{current_stage} could only be performed after #{allowed_stages} stage(s)"
    end

    def preflight_check!
      # Check that no other operation is in progress
      if current_task
        raise StandardError, 'There is another job in progress. Aborting'
      end

      unless elastic_helper.alias_exists?
        raise StandardError, 'You should use aliases feature to be able to perform this operation'
      end

      index_size = elastic_helper.index_size_bytes
      if elastic_helper.cluster_free_size_bytes < index_size
        raise StandardError, "You should have at least #{index_size} bytes of storage available to perform this operation"
      end
    end

    def default_index_options
      {
        refresh_interval: nil, # Change it back to the default
        number_of_replicas: Gitlab::CurrentSettings.elasticsearch_replicas,
        translog: { durability: 'request' }
      }
    end

    def initial_stage!
      ReindexingTask.create!

      # Pause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)
    end

    def indexing_stage!
      current_task.update!(stage: :indexing)

      # Create an index with custom settings
      index_name = elastic_helper.create_empty_index(with_alias: false, options: { settings: INDEX_OPTIONS })

      # Record documents count
      documents_count = elastic_helper.index_size.dig('docs', 'count')

      # Trigger reindex
      task_id = elastic_helper.reindex(to: index_name)

      current_task.update!(
        index_name_from: elastic_helper.target_index_name,
        index_name_to: index_name,
        documents_count: documents_count,
        elastic_task: task_id
      )

      true
    rescue StandardError => e
      abort_indexing!(e)

      raise e
    end

    def final_stage!
      task = current_task

      task.update!(stage: :final)

      # Check if indexing is completed
      return false unless elastic_helper.task_status(task_id: task.elastic_task)['completed']

      # Refresh a new index
      elastic_helper.refresh_index(index_name: task.index_name_to)

      # Compare documents count
      old_documents_count = task.documents_count
      new_documents_count = elastic_helper.index_size(index_name: task.index_name_to).dig('docs', 'count')
      raise StandardError, "Documents count is different, #{new_documents_count} != #{old_documents_count}" if old_documents_count != new_documents_count

      # Change index settings back
      elastic_helper.update_settings(index_name: task.index_name_to, settings: default_index_options)

      # Switch alias to a new index
      elastic_helper.switch_alias(to: task.index_name_to)

      # Drop an old index
      elastic_helper.delete_index(index_name: task.index_name_from)

      # Unpause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)

      task.update!(stage: :success)

      true
    rescue StandardError => e
      abort_indexing!(e)

      raise e
    end

    def abort_indexing!(exception)
      current_task.update!(
        stage: :failure,
        error_message: "#{exception.class}: #{exception.message}"[0, 255]
      )

      # Unpause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)

      # Remove index
      index_name = current_task&.index_name_to
      elastic_helper.delete_index(index_name: index_name) if index_name
    end

    def elastic_helper
      Gitlab::Elastic::Helper.default
    end
  end
end
