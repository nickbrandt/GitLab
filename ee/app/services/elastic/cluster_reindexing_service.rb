# frozen_string_literal: true

module Elastic
  class ClusterReindexingService
    REDIS_KEY = 'elastic:cluster_reindexing_service:job'

    def execute(stage: :initial)
      case stage.to_sym
      when :initial
        preflight_check!

        initial_stage!
      when :indexing
        indexing_stage!
      when :final
        final_stage!
      end
    end

    def current_job
      with_redis do |redis|
        body = redis.get(REDIS_KEY)

        Gitlab::Json.parse(body).with_indifferent_access if body
      end
    end

    private

    def preflight_check!
      # Check that no other operation is in progress
      if current_job
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

    def index_options(for_reindexing:)
      if for_reindexing
        {
         number_of_replicas: 0,
         translog: { durability: 'async' }
        }
      else
        {
         number_of_replicas: Gitlab::CurrentSettings.elasticsearch_replicas,
         translog: { durability: 'request' }
        }
      end
    end

    def initial_stage!
      # Pause indexing
      ApplicationSetting.current.update!(elasticsearch_pause_indexing: true)
    end

    def indexing_stage!
      # Create an index with custom settings
      index_name = elastic_helper.create_empty_index(with_alias: false, options: { settings: index_options(for_reindexing: true) })

      # Record documents count
      documents_count = elastic_helper.index_size.dig('docs', 'count')

      # Trigger reindex
      task_id = elastic_helper.reindex(to: index_name)

      # Save job info
      info = {
        old_index_name: elastic_helper.target_index_name,
        index_name: index_name,
        documents_count: documents_count,
        task_id: task_id
      }

      with_redis do |redis|
        redis.set(REDIS_KEY, info.to_json)
      end

      info
    rescue StandardError => e
      abort_indexing!(index_name)

      raise e
    end

    def final_stage!
      job_info = current_job

      raise StandardError, "Indexing is not started" unless job_info

      # Check if indexing is completed
      return false unless elastic_helper.task_status(task_id: job_info[:task_id])['completed']

      # Refresh a new index
      elastic_helper.refresh_index(index_name: job_info[:index_name])

      # Compare documents count
      old_documents_count = job_info[:documents_count]
      new_documents_count = elastic_helper.index_size.dig('docs', 'count')
      raise StandardError, "Documents count is different, #{new_documents_count} != #{old_documents_count}" if old_documents_count != new_documents_count

      # Change index settings back
      elastic_helper.update_settings(index_name: job_info[:index_name], settings: index_options(for_reindexing: false))

      # Switch alias to a new index
      elastic_helper.switch_alias(to: job_info[:index_name])

      # Drop an old index
      elastic_helper.delete_index(index_name: job_info[:old_index_name])

      # Unpause indexing
      ApplicationSetting.current.update!(elasticsearch_pause_indexing: false)

      # Remove job info from redis
      delete_current_job!

      true
    rescue StandardError => e
      abort_indexing!(job_info.try(:[], :index_name))

      raise e
    end

    def abort_indexing!(index_name)
      # Unpause indexing
      ApplicationSetting.current.update!(elasticsearch_pause_indexing: false)

      # Remove index
      elastic_helper.delete_index(index_name: index_name) if index_name

      # Remove job info from redis
      delete_current_job!
    end

    def delete_current_job!
      with_redis do |redis|
        redis.del(REDIS_KEY)
      end
    end

    def with_redis(&blk)
      Gitlab::Redis::SharedState.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end

    def elastic_helper
      Gitlab::Elastic::Helper.default
    end
  end
end
