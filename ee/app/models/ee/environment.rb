module EE
  module Environment
    def pod_names
      return [] unless rollout_status

      rollout_status.instances.map do |instance|
        instance[:pod_name]
      end
    end

    def protected?
      protected_environments.exists?(name: name)
    end

    def protected_deployable_by_user(user)
      protected_env = protected_environments.find_by(name: name)

      return true unless protected_env

      protected_env.accessible_to?(user)
    end

    private

    def protected_environments
      @protected_environments ||= project.protected_environments
    end
  end
end
