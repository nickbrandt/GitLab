module EE
  module ProtectedScope
    extend ::Gitlab::Utils::Override

    override :review_protected_environment_scope
    def review_protected_environment_scope
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
