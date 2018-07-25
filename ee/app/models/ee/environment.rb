module EE
  module Environment
    def pod_names
      return [] unless rollout_status

      rollout_status.instances.map do |instance|
        instance[:pod_name]
      end
    end

    def protected?
      protected_environments_feature_available? &&
        protected_environment
    end

    def protected_deployable_by_user(user)
      return true unless self.protected?

      protected_environment.accessible_to?(user)
    end

    private

    def protected_environments_feature_available?
      project.feature_available?(:protected_environments)
    end

    def protected_environments
      @protected_environments ||= project.protected_environments
    end

    def protected_environment
      @protected_environment ||= protected_environments.find_by(name: name)
    end
  end
end
