# frozen_string_literal: true

module WorkerAttributes
  extend ActiveSupport::Concern
  include Gitlab::ClassAttributes

  # Resource boundaries that workers can declare through the
  # `resource_boundary` attribute
  VALID_RESOURCE_BOUNDARIES = [:memory, :cpu, :unknown].freeze

  # Urgencies that workers can declare through the `urgencies` attribute
  VALID_URGENCIES = [:high, :low, :throttled].freeze

  VALID_DATA_CONSISTENCIES = [:always, :sticky, :delayed].freeze

  NAMESPACE_WEIGHTS = {
    auto_devops: 2,
    auto_merge: 3,
    chaos: 2,
    deployment: 3,
    mail_scheduler: 2,
    notifications: 2,
    pipeline_cache: 3,
    pipeline_creation: 4,
    pipeline_default: 3,
    pipeline_hooks: 2,
    pipeline_processing: 5,

    # EE-specific
    epics: 2,
    incident_management: 2,
    security_scans: 2
  }.stringify_keys.freeze

  class_methods do
    def feature_category(value, *extras)
      raise "Invalid category. Use `feature_category_not_owned!` to mark a worker as not owned" if value == :not_owned

      class_attributes[:feature_category] = value
    end

    # Special case: mark this work as not associated with a feature category
    # this should be used for cross-cutting concerns, such as mailer workers.
    def feature_category_not_owned!
      class_attributes[:feature_category] = :not_owned
    end

    def get_feature_category
      get_class_attribute(:feature_category)
    end

    def feature_category_not_owned?
      get_feature_category == :not_owned
    end

    # This should be set to :high for jobs that need to be run
    # immediately, or, if they are delayed, risk creating
    # inconsistencies in the application that could being perceived by
    # the user as incorrect behavior (ie, a bug)
    #
    # See
    # doc/development/sidekiq_style_guide.md#urgency
    # for details
    def urgency(urgency)
      raise "Invalid urgency: #{urgency}" unless VALID_URGENCIES.include?(urgency)

      class_attributes[:urgency] = urgency
    end

    def get_urgency
      class_attributes[:urgency] || :low
    end

    def data_consistency(data_consistency, feature_flag: nil)
      raise ArgumentError, "Invalid data consistency: #{data_consistency}" unless VALID_DATA_CONSISTENCIES.include?(data_consistency)
      raise ArgumentError, 'Data consistency is already set' if class_attributes[:data_consistency]

      class_attributes[:data_consistency_feature_flag] = feature_flag if feature_flag
      class_attributes[:data_consistency] = data_consistency

      validate_worker_attributes!
    end

    def validate_worker_attributes!
      # Since the deduplication should always take into account the latest binary replication pointer into account,
      # not the first one, the deduplication will not work with sticky or delayed.
      # Follow up issue to improve this: https://gitlab.com/gitlab-org/gitlab/-/issues/325291
      if idempotent? && get_data_consistency != :always
        raise ArgumentError, "Class can't be marked as idempotent if data_consistency is not set to :always"
      end
    end

    def get_data_consistency
      class_attributes[:data_consistency] || :always
    end

    def get_data_consistency_feature_flag_enabled?
      return true unless class_attributes[:data_consistency_feature_flag]

      Feature.enabled?(class_attributes[:data_consistency_feature_flag], default_enabled: :yaml)
    end

    def max_replica_retry_count(value)
      class_attributes[:max_replica_retry_count] = value
    end

    def get_max_replica_retry_count
      get_class_attribute(:max_replica_retry_count) || 1
    end

    # Set this attribute on a job when it will call to services outside of the
    # application, such as 3rd party applications, other k8s clusters etc See
    # doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies for
    # details
    def worker_has_external_dependencies!
      class_attributes[:external_dependencies] = true
    end

    # Returns a truthy value if the worker has external dependencies.
    # See doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies
    # for details
    def worker_has_external_dependencies?
      class_attributes[:external_dependencies]
    end

    def worker_resource_boundary(boundary)
      raise "Invalid boundary" unless VALID_RESOURCE_BOUNDARIES.include? boundary

      class_attributes[:resource_boundary] = boundary
    end

    def get_worker_resource_boundary
      class_attributes[:resource_boundary] || :unknown
    end

    def idempotent!
      class_attributes[:idempotent] = true

      validate_worker_attributes!
    end

    def idempotent?
      class_attributes[:idempotent]
    end

    def weight(value)
      class_attributes[:weight] = value
    end

    def get_weight
      class_attributes[:weight] ||
        NAMESPACE_WEIGHTS[queue_namespace] ||
        1
    end

    def tags(*values)
      class_attributes[:tags] = values
    end

    def get_tags
      Array(class_attributes[:tags])
    end

    def deduplicate(strategy, options = {})
      class_attributes[:deduplication_strategy] = strategy
      class_attributes[:deduplication_options] = options
    end

    def get_deduplicate_strategy
      class_attributes[:deduplication_strategy] ||
        Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob::DEFAULT_STRATEGY
    end

    def get_deduplication_options
      class_attributes[:deduplication_options] || {}
    end

    def big_payload!
      class_attributes[:big_payload] = true
    end

    def big_payload?
      class_attributes[:big_payload]
    end
  end
end
