# frozen_string_literal: true

module EE
  class Namespace::RootStorageSize
    def initialize(root_namespace)
      @root_namespace = root_namespace
    end

    def above_size_limit?
      usage_ratio > 1
    end

    def usage_ratio
      return 0 if limit == 0

      current_size.to_f / limit.to_f
    end

    def current_size
      @current_size ||= root_namespace.root_storage_statistics&.storage_size
    end

    def limit
      @limit ||= root_namespace.actual_limits.storage_size_limit.megabytes +
      root_namespace.additional_purchased_storage_size.megabytes
    end

    private

    attr_reader :root_namespace
  end
end
