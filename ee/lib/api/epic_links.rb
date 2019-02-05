# frozen_string_literal: true

module API
  class EpicLinks < Grape::API
    include ::Gitlab::Utils::StrongMemoize

    before do
      authenticate!
      authorize_epics_feature!
    end

    helpers ::API::Helpers::EpicsHelpers

    helpers do
      def child_epic
        strong_memoize(:child_epic) do
          find_epics(finder_params: { group_id: user_group.id })
            .find_by_id(declared_params[:child_epic_id])
        end
      end

      params :child_epic_id do
        # Unique ID should be used because epics from other groups can be assigned as child.
        requires :child_epic_id, type: Integer, desc: 'The global ID of the epic that will be assigned as child'
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
      requires :epic_iid, type: Integer, desc: 'The internal ID of an epic'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get related epics' do
        success EE::API::Entities::Epic
      end
      get ':id/(-/)epics/:epic_iid/epics' do
        authorize_can_read!

        child_epics = EpicsFinder.new(current_user, parent_id: epic.id, group_id: user_group.id).execute

        present child_epics, with: EE::API::Entities::Epic
      end

      desc 'Relate epics' do
        success EE::API::Entities::Epic
      end
      params do
        use :child_epic_id
      end
      post ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_can_admin!

        create_params = { target_issuable: child_epic }

        result = ::EpicLinks::CreateService.new(epic, current_user, create_params).execute

        if result[:status] == :success
          present child_epic, with: EE::API::Entities::Epic
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc 'Remove epics relation'
      params do
        use :child_epic_id
      end
      delete ':id/(-/)epics/:epic_iid/epics/:child_epic_id' do
        authorize_can_admin!

        updated_epic = ::Epics::UpdateService.new(user_group, current_user, { parent: nil }).execute(child_epic)

        present updated_epic, with: EE::API::Entities::Epic
      end
    end
  end
end
