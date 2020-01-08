# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Status
        module Build
          module Failed
            extend ActiveSupport::Concern

            prepended do
              EE_REASONS = const_get(:REASONS, false).merge(
                protected_environment_failure: 'protected environment failure',
                invalid_bridge_trigger: 'downstream pipeline trigger definition is invalid',
                downstream_bridge_project_not_found: 'downstream project could not be found',
                upstream_bridge_project_not_found: 'upstream project could not be found',
                insufficient_bridge_permissions: 'no permissions to trigger downstream pipeline',
                insufficient_upstream_permissions: 'no permissions to read upstream project',
                bridge_pipeline_is_child_pipeline: 'creation of child pipeline not allowed from another child pipeline'
              ).freeze
              EE::Gitlab::Ci::Status::Build::Failed.private_constant :EE_REASONS
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :reasons
              def reasons
                EE_REASONS
              end
            end
          end
        end
      end
    end
  end
end
