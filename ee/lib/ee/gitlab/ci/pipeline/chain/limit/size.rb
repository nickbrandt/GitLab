# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          module Limit
            module Size
              extend ::Gitlab::Utils::Override
              include ::Gitlab::Ci::Pipeline::Chain::Helpers

              attr_reader :limit
              private :limit

              def initialize(*)
                super

                @limit = Pipeline::Quota::Size
                  .new(project.namespace, pipeline, command)
              end

              override :perform!
              def perform!
                return unless limit.exceeded?

                limit.log_error!(log_attrs)

                return unless limit.enabled?

                error(limit.message, drop_reason: :size_limit_exceeded)
              end

              override :break?
              def break?
                limit.enabled? && limit.exceeded?
              end

              def log_attrs
                {
                  pipeline_source: pipeline.source,
                  plan: project.actual_plan_name,
                  project_id: project.id,
                  project_name: project.name
                }
              end
            end
          end
        end
      end
    end
  end
end
