module EE
  module Projects
    module Settings
      module CiCdController
        extend ActiveSupport::Concern

        prepended do
          before_action :load_gon_index, only: :show
        end

        private

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        def define_variables
          super

          @protected_environment = @project.protected_environments.new
        end

        def load_gon_index
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
