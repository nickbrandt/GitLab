module EE
  module Projects
    module Settings
      module CiCdController
        extend ActiveSupport::Concern

        prepended do
          before_action :assign_variables_to_gon, only: :show
          before_action :define_protected_env_variables, only: :show
        end

        private

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        def define_protected_env_variables
          @protected_environments = @project.protected_environments.order(:name)
          @protected_environments_count = @protected_environments.count
          @protected_environment = @project.protected_environments.new
        end

        def assign_variables_to_gon
          gon.push(current_project_id: project.id)
          gon.push(deploy_access_levels)
          gon.push(protectable_environments_for_dropdown)
        end

        def protectable_environments_for_dropdown
          { open_environments: environment_dropdown.env_hash }
        end

        def deploy_access_levels
          { deploy_access_levels: environment_dropdown.roles_hash }
        end

        def environment_dropdown
          @environment_dropdown ||= ProtectedEnvironments::EnvironmentDropdown.new(@project)
        end
      end
    end
  end
end
