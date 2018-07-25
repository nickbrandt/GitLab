module EE
  module ProtectedEnvironmentScope
    extend ::Gitlab::Utils::Override

    override :entitled_to_environment?
    def entitled_to_environment?
      self.drop(:protected_environment_failure) if protected_environment?
    end

    private

    def protected_environment?
      user &&
        has_environment? &&
        !project.protected_environment_accessible_to?(expanded_environment_name, user)
    end
  end
end
