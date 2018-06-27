module EE
  module Environment
    def pod_names
      return [] unless rollout_status

      rollout_status.instances.map do |instance|
        instance[:pod_name]
      end
    end

    def protected?
      ProtectedEnvironment.protected?(project, name)
    end

    def protected_deployable_by_user?(user)
      ProtectedEnvironment.protected_ref_accessible_to?(name, user, project: project, action: :deploy)
    end
  end
end
