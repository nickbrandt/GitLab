# frozen_string_literal: true

module API
  class Scim < Grape::API
    prefix 'api/scim'
    version 'v2'
    content_type :json, 'application/scim+json'

    namespace 'groups/:group' do
      params do
        requires :group, type: String
      end

      resource :Users do
        before do
          check_group_saml_configured
          authenticate!
        end

        desc 'Returns 200 if authenticated'
        get do
          group = find_group!(params[:group])

          authorize_manage_saml!(group)

          status 200

          {} # Dummy, just used to verify the connection by IdPs at the moment
        end

        desc 'Removes a SAML user'
        params do
          requires :external_id, type: Integer, desc: 'The external ID of the member'
        end
        delete ":external_id" do
          group = find_group!(params[:group])

          authorize_manage_saml!(group)

          user = User.find_by_email(params[:external_id])

          not_found!('User') unless user

          linked_identity = GroupSamlIdentityFinder.new(user: user).find_linked(group: group)

          GroupSaml::Identity::DestroyService.new(linked_identity).execute
        end
      end
    end
  end
end
