# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class MergeRequestDiffBase < Base
        extend ::Gitlab::Utils::Override

        def initialize(merge_request_diff, diff_options:)
          @merge_request_diff = merge_request_diff

          super(merge_request_diff,
            project: merge_request_diff.project,
            diff_options: diff_options,
            diff_refs: merge_request_diff.diff_refs,
            fallback_diff_refs: merge_request_diff.fallback_diff_refs)
        end

        def diff_files(decorate_diff_files: true)
          files = super()

          return files unless decorate_diff_files

          strong_memoize(:decorated_diff_files) do
            files.each { |diff_file| cache.decorate(diff_file) }

            files
          end
        end

        override :write_cache
        def write_cache
          cache.write_if_empty
        end

        override :clear_cache
        def clear_cache
          cache.clear
        end

        def cache_key
          cache.key
        end

        def real_size
          @merge_request_diff.real_size
        end

        private

        def cache
          @cache ||= if Feature.enabled?(:hset_redis_diff_caching, project)
                       Gitlab::Diff::HighlightCache.new(self)
                     else
                       Gitlab::Diff::DeprecatedHighlightCache.new(self)
                     end
        end
      end
    end
  end
end
