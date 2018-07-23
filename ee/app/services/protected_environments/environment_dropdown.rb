module ProtectedEnvironments
  class EnvironmentDropdown
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def protectable_env_names
      env_names - protected_environment_names
    end

    def env_hash
      protectable_env_names.map { |env_name| { text: env_name, id: env_name, title: env_name } }
    end

    def roles_hash
      { roles: roles }
    end

    def roles
      human_access_levels.map do |id, text|
        { id: id, text: text, before_divider: true }
      end
    end

    private

    def env_names
      environments.map(&:name)
    end

    def protected_environment_names
      protected_environments.map(&:name)
    end

    def protected_environments
      @protected_environments ||= project.protected_environments
    end

    def environments
      @environments ||= project.environments
    end

    def human_access_levels
      ::ProtectedEnvironment::DeployAccessLevel::HUMAN_ACCESS_LEVELS
    end
  end
end
