module EE
  module Projects
    module Settings
      module CiCdController
        extend ActiveSupport::Concern

        prepended do
          before_action :load_gon_index, only: :show
        end

        private

        def load_gon_index
          gon.push(current_project_id: project.id) if project
          gon.push(deploy_access_levels: levels_for_dropdown)
          gon.push(protectable_environments_for_dropdown)
        end

        def protectable_environments_for_dropdown
          # For testing purposes (to be implemented soon)
          hardcoded_output = [{text: 'staging', id: 'staging', title: 'staging'}, {text: 'production', id: 'production', title: 'production'}]

          { open_environments: hardcoded_output }
        end

        def levels_for_dropdown
          roles = ::ProtectedRefAccess::HUMAN_ACCESS_LEVELS.map do |id, text|
            { id: id, text: text, before_divider: true }
          end
          { roles: roles }
        end
      end
    end
  end
end
