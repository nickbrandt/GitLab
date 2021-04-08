# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      class SidekiqServerMiddleware
        def call(worker, job, _queue)
          if requires_primary?(worker.class, job)
            Session.current.use_primary!
          end

          yield unless job[:database_chosen] == 'retry'
        ensure
          clear
        end

        private

        def clear
          load_balancer.release_host
          Session.clear_session
        end

        def requires_primary?(worker_class, job)
          return true unless worker_class.include?(::ApplicationWorker)
          return true if worker_class.get_data_consistency == :always
          return true unless worker_class.get_data_consistency_feature_flag_enabled?

          check_for_replica(worker.class, job)

          job[:database_chosen] == 'primary'
        end

        def check_for_replica(worker_class, job)
          location = job['database_replica_location'] || job['database_write_location']

          if replica_caught_up?(location)
            job[:database_chosen] = 'replica'
          elsif worker_class.get_data_consistency == :delayed
            attempt_retry(worker_class, job)
          else
            job[:database_chosen] = 'primary'
          end
        end

        def attempt_retry(worker_class, job)
          max_retry_attempts = worker_class.get_max_replica_retry_count

          count = job["delayed_retry_count"] = job["delayed_retry_count"].to_i + 1

          if count < max_retry_attempts
            retry_at = Time.now.to_f + delay(count)
            payload = Sidekiq.dump_json(job)
            Sidekiq.redis do |conn|
              conn.zadd("retry", retry_at.to_s, payload)
            end
            job[:database_chosen] = 'retry'
          else
            job[:database_chosen] = 'primary'
          end
        end

        def delay(count)
          (count**4) + 15 + (rand(30) * (count + 1))
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end

        def replica_caught_up?(location)
          return true unless location

          load_balancer.host.caught_up?(location)
        end
      end
    end
  end
end
