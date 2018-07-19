module EE
  module Environment
    def pod_names
      return [] unless rollout_status

      rollout_status.instances.map do |instance|
        instance[:pod_name]
      end
    end

    def protected?
      project.protected_environments.exists?(name: name)
    end

    def protected_deployable_by_user(user)
      protected_env = project.protected_environments.find_by(name: name)

      return true unless protected_env

      protected_env.accessible_to?(user)
    end
  end
end
