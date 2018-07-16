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
  end
end
