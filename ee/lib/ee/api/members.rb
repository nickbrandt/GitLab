# frozen_string_literal: true

module EE
  module API
    module Members
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, type: String, desc: 'The ID of a group'
        end
        resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Overrides a member of a group.' do
            success Entities::Member
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          # rubocop: disable CodeReuse/ActiveRecord
          post ":id/members/:user_id/override" do
            source = find_source(:group, params.delete(:id))
            authorize_admin_source!(:group, source)

            member = source.members.find_by!(user_id: params[:user_id])
            updated_member =
              ::Members::UpdateService
                .new(current_user, { override: true })
                .execute(member, permission: :override)

            if updated_member.valid?
              present updated_member, with: ::API::Entities::Member
            else
              render_validation_error!(updated_member)
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          desc 'Remove an override of a member of a group.' do
            success Entities::Member
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          # rubocop: disable CodeReuse/ActiveRecord
          delete ":id/members/:user_id/override" do
            source = find_source(:group, params.delete(:id))
            authorize_admin_source!(:group, source)

            member = source.members.find_by!(user_id: params[:user_id])
            updated_member =
              ::Members::UpdateService
                .new(current_user, { override: false })
                .execute(member, permission: :override)

            if updated_member.valid?
              present updated_member, with: ::API::Entities::Member
            else
              render_validation_error!(updated_member)
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
