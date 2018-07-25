module EE
  module EnvironmentPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:protected_environment) { protected_environment? }

      condition(:deployable_by_user) { deployable_by_user? }

      condition(:developer) { developer? }

      rule { protected_environment & (~deployable_by_user | developer) }.policy do
        prevent :stop_environment
      end

      private

      def deployable_by_user?
        @subject.protected_deployable_by_user(@user)
      end

      def protected_environment?
        @subject.protected?
      end

      def developer?
        access_level == ::Gitlab::Access::DEVELOPER
      end

      def access_level
        return -1 if @user.nil?

        @subject.project.team.max_member_access(@user.id)
      end
    end
  end
end
