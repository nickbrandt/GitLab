# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Quota
          class Size < Ci::Limit
            include ::Gitlab::Utils::StrongMemoize
            include ActionView::Helpers::TextHelper

            def initialize(namespace, pipeline)
              @namespace = namespace
              @pipeline = pipeline
            end

            def enabled?
              ci_pipeline_size_limit > 0
            end

            def exceeded?
              return false unless enabled?

              excessive_seeds_count > 0
            end

            def message
              return unless exceeded?

              'Pipeline size limit exceeded by ' \
                "#{pluralize(excessive_seeds_count, 'job')}!"
            end

            private

            def excessive_seeds_count
              @excessive ||= @pipeline.seeds_size - ci_pipeline_size_limit
            end

            def ci_pipeline_size_limit
              strong_memoize(:ci_pipeline_size_limit) do
                @namespace.actual_limits.ci_pipeline_size
              end
            end
          end
        end
      end
    end
  end
end
