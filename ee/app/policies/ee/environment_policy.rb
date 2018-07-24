module EE
  module EnvironmentPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:protected_environment) { protected_environment? }

      condition(:deployable_by_user) { deployable_by_user? }

      condition(:maintainer_or_admin) { maintainer_or_admin? }

      condition(:admin) { admin? }

      rule { (protected_environment & ~deployable_by_user) | ~maintainer_or_admin }.policy do
        prevent :stop_environment
      end

      private

      def deployable_by_user?
        @subject.protected_deployable_by_user(@user)
      end

      def protected_environment?
        @subject.protected?
      end

      def maintainer_or_admin?
        maintainer? || admin?
      end

      def maintainer?
        access_level >= ::Gitlab::Access::MAINTAINER
      end

      def admin?
        @user.admin?
      end

      def access_level
        return -1 if @user.nil?

        @subject.project.team.max_member_access(@user.id)
      end
    end
  end
end
