# frozen_string_literal: true

require 'yaml'

module Gitlab
  module SidekiqConfig
    FOSS_QUEUE_CONFIG_PATH = 'app/workers/all_queues.yml'
    EE_QUEUE_CONFIG_PATH = 'ee/app/workers/all_queues.yml'
    SIDEKIQ_QUEUES_PATH = 'config/sidekiq_queues.yml'

    QUEUE_CONFIG_PATHS = [
      FOSS_QUEUE_CONFIG_PATH,
      (EE_QUEUE_CONFIG_PATH if Gitlab.ee?)
    ].compact.freeze

    DEFAULT_WORKERS = [
      DummyWorker.new('default', weight: 1),
      DummyWorker.new('mailers', weight: 2)
    ].map { |worker| Gitlab::SidekiqConfig::Worker.new(worker, ee: false) }.freeze

    class << self
      include Gitlab::SidekiqConfig::CliMethods

      def redis_queues
        # Not memoized, because this can change during the life of the application
        Sidekiq::Queue.all.map(&:name)
      end

      def config_queues
        @config_queues ||= begin
          config = YAML.load_file(Rails.root.join(SIDEKIQ_QUEUES_PATH))
          config[:queues].map(&:first)
        end
      end

      def cron_workers
        @cron_workers ||= Settings.cron_jobs.map { |job_name, options| options['job_class'].constantize }
      end

      def workers
        @workers ||= begin
          result = []
          result.concat(DEFAULT_WORKERS)
          result.concat(find_workers(Rails.root.join('app', 'workers'), ee: false))

          if Gitlab.ee?
            result.concat(find_workers(Rails.root.join('ee', 'app', 'workers'), ee: true))
          end

          result
        end
      end

      def workers_for_all_queues_yml
        workers.partition(&:ee?).reverse.map(&:sort)
      end

      # YAML.load_file is OK here as we control the file contents
      def all_queues_yml_outdated?
        foss_workers, ee_workers = workers_for_all_queues_yml

        return true if foss_workers != YAML.load_file(FOSS_QUEUE_CONFIG_PATH)

        Gitlab.ee? && ee_workers != YAML.load_file(EE_QUEUE_CONFIG_PATH)
      end

      def queues_for_sidekiq_queues_yml
        namespaces_with_equal_weights =
          workers
            .group_by(&:queue_namespace)
            .map(&:last)
            .select { |workers| workers.map(&:get_weight).uniq.count == 1 }
            .map(&:first)

        namespaces = namespaces_with_equal_weights.map(&:queue_namespace).to_set
        remaining_queues = workers.reject { |worker| namespaces.include?(worker.queue_namespace) }

        (namespaces_with_equal_weights.map(&:namespace_and_weight) +
         remaining_queues.map(&:queue_and_weight)).sort
      end

      # YAML.load_file is OK here as we control the file contents
      def sidekiq_queues_yml_outdated?
        config_queues = YAML.load_file(SIDEKIQ_QUEUES_PATH)[:queues]

        queues_for_sidekiq_queues_yml != config_queues
      end

      private

      def find_workers(root, ee:)
        concerns = root.join('concerns').to_s

        Dir[root.join('**', '*.rb')]
          .reject { |path| path.start_with?(concerns) }
          .map { |path| worker_from_path(path, root) }
          .select { |worker| worker < Sidekiq::Worker }
          .map { |worker| Gitlab::SidekiqConfig::Worker.new(worker, ee: ee) }
      end

      def worker_from_path(path, root)
        ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')

        ns.camelize.constantize
      end
    end

    def self.query_workers(query_string)
      predicate = query_string_to_lambda(query_string)

      workers.filter(&predicate)
    end

    def self.query_string_to_lambda(query_string)
      or_clauses = query_string.split(%r{\s+}).map do |and_clauses_string|
        and_clauses_predicates = and_clauses_string.split(',').map do |term|
          match = term.match(%r{^(\w+)(!?=)([\w|]+)})
          raise "invalid term #{term}" unless match

          lhs = match[1]
          op = match[2]
          rhs = match[3]

          predicate_for_op(op, predicate_factory(lhs, rhs.split('|')))
        end

        lambda { |worker| and_clauses_predicates.all? { |predicate| predicate.call(worker) } }
      end

      lambda { |worker| or_clauses.any? { |predicate| predicate.call(worker) } }
    end

    def self.predicate_for_op(op, predicate)
      case op
      when "="
        predicate
      when "!="
        lambda { |worker| !predicate.call(worker) }
      else
        raise "unknown op #{op}"
      end
    end

    def self.predicate_factory(lhs, values)
      case lhs
      when "resource_boundary"
        values_sym = values.map(&:to_sym)
        lambda { |worker| values_sym.include? worker.get_worker_resource_boundary }

      when "latency_sensitive"
        values_bool = values.map { |v| v.casecmp("true").zero? }
        lambda { |worker| values_bool.include? worker.latency_sensitive_worker? }

      when "feature_category"
        values_sym = values.map(&:to_sym)
        lambda { |worker| values_sym.include? worker.get_feature_category }
      else
        raise "unknown predicate #{lhs}"
      end
    end
  end
end
