# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        module Common
          def label
            subject.description
          end

          def has_details?
            can?(user, :read_pipeline, subject.first_downstream_pipeline)
          end

          def details_path
            return unless subject.first_downstream_pipeline

            pipeline = subject.first_downstream_pipeline
            project_pipeline_path(pipeline.project, pipeline)
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
