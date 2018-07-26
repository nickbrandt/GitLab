# frozen_string_literal: true

module EE
  module DeploymentPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:protected_environment) { protected_environment? }

      condition(:deployable_by_user) { deployable_by_user? }

      rule { protected_environment & ~deployable_by_user }.policy do
        prevent :create_deployment
      end

      private

      def deployable_by_user?
        environment.protected_deployable_by_user(@user)
      end

      def protected_environment?
        environment && environment.protected?
      end

      def environment
        @environment ||= @subject.environment
      end
    end
  end
end
