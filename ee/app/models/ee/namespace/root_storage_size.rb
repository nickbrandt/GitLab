# frozen_string_literal: true

module EE
  class Namespace::RootStorageSize
    CURRENT_SIZE_CACHE_KEY = 'root_storage_current_size'
    LIMIT_CACHE_KEY = 'root_storage_size_limit'
    EXPIRATION_TIME = 10.minutes

    def initialize(root_namespace)
      @root_namespace = root_namespace
    end

    def above_size_limit?
      return false if root_namespace.temporary_storage_increase_enabled?

      usage_ratio > 1
    end

    def usage_ratio
      return 0 if limit == 0

      current_size.to_f / limit.to_f
    end

    def current_size
      @current_size ||= Rails.cache.fetch(['namespaces', root_namespace.id, CURRENT_SIZE_CACHE_KEY], expires_in: EXPIRATION_TIME) do
        root_namespace.root_storage_statistics&.storage_size
      end
    end

    def limit
      @limit ||= Rails.cache.fetch(['namespaces', root_namespace.id, LIMIT_CACHE_KEY], expires_in: EXPIRATION_TIME) do
        root_namespace.actual_limits.storage_size_limit.megabytes +
            root_namespace.additional_purchased_storage_size.megabytes
      end
    end

    private

    attr_reader :root_namespace
  end
end
