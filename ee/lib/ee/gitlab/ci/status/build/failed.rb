# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Status
        module Build
          module Failed
            extend ActiveSupport::Concern

            prepended do
              EE_REASONS = const_get(:REASONS).merge(
                protected_environment_failure: 'protected environment failure',
                invalid_bridge_trigger: 'downstream pipeline trigger definition is invalid',
                insufficient_bridge_permissions: 'no permissions to trigger downstream pipeline'
              ).freeze

              EE::Gitlab::Ci::Status::Build::Failed.private_constant :EE_REASONS
            end

            class_methods do
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
