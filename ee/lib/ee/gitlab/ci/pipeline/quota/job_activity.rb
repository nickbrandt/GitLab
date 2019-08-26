# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Quota
          class JobActivity < Ci::Limit
            include ::Gitlab::Utils::StrongMemoize
            include ActionView::Helpers::TextHelper

            def initialize(namespace, project)
              @namespace = namespace
              @project = project
            end

            def enabled?
              strong_memoize(:enabled) do
                @namespace.max_active_jobs > 0
              end
            end

            def exceeded?
              return false unless enabled?

              excessive_jobs_count > 0
            end

            def message
              return unless exceeded?

              'Active jobs limit exceeded by ' \
                "#{pluralize(excessive_jobs_count, 'job')} in the past 24 hours!"
            end

            private

            def excessive_jobs_count
              @excessive ||= jobs_in_alive_pipelines_count - max_active_jobs_count
            end

            # rubocop: disable CodeReuse/ActiveRecord
            def jobs_in_alive_pipelines_count
              @project.all_pipelines.created_after(24.hours.ago).alive.joins(:builds).count
            end
            # rubocop: enable CodeReuse/ActiveRecord

            def max_active_jobs_count
              @namespace.max_active_jobs
            end
          end
        end
      end
    end
  end
end
