# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Failed < Status::Extended
          # TODO: This file is very similar to Status::Build::Failed, consider to have a common class
          # TODO: These all REASONS may not be necessary for this class. Also there may be redundant REASONS in Status::Build::Failed.
          REASONS = {
            unknown_failure: 'unknown failure',
            script_failure: 'script failure',
            api_failure: 'API failure',
            stuck_or_timeout_failure: 'stuck or timeout failure',
            runner_system_failure: 'runner system failure',
            missing_dependency_failure: 'missing dependency failure',
            runner_unsupported: 'unsupported runner',
            stale_schedule: 'stale schedule',
            job_execution_timeout: 'job execution timeout',
            archived_failure: 'archived failure',
            unmet_prerequisites: 'unmet prerequisites',
            scheduler_failure: 'scheduler failure',
            data_integrity_failure: 'data integrity failure',
            forward_deployment_failure: 'forward deployment failure',
            invalid_bridge_trigger: 'downstream pipeline trigger definition is invalid',
            downstream_bridge_project_not_found: 'downstream project could not be found',
            insufficient_bridge_permissions: 'no permissions to trigger downstream pipeline',
            bridge_pipeline_is_child_pipeline: 'creation of child pipeline not allowed from another child pipeline',
            downstream_pipeline_creation_failed: 'downstream pipeline can not be created'
          }.freeze

          private_constant :REASONS

          def status_tooltip
            base_message
          end

          def badge_tooltip
            base_message
          end

          def self.matches?(bridge, user)
            bridge.failed?
          end

          def self.reasons
            REASONS
          end

          private

          def base_message
            "#{s_('CiStatusLabel|failed')} #{description}"
          end

          def description
            "- (#{failure_reason_message})"
          end

          def failure_reason_message
            [
              self.class.reasons.fetch(subject.failure_reason.to_sym),
              subject.description
            ].compact.join(', ')
          end
        end
      end
    end
  end
end
