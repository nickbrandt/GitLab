# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Retryable < Status::Extended
          def has_action?
            can?(user, :update_pipeline, downstream_pipeline)
          end

          def action_icon
            'retry'
          end

          def action_title
            'Retry'
          end

          def action_button_title
            _('Retry the downstream pipeline')
          end

          def action_path
            retry_project_pipeline_path(downstream_project, downstream_pipeline)
          end

          def action_method
            :post
          end

          def self.matches?(bridge, _user)
            bridge.retryable?
          end

          private

          def downstream_pipeline
            subject.downstream_pipeline
          end

          def downstream_project
            downstream_pipeline&.project
          end
        end
      end
    end
  end
end
