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

      helpers do
        def logger
          API.logger
        end

        def destroy_identity(identity)
          GroupSaml::Identity::DestroyService.new(identity).execute

          true
        rescue => e
          logger.error(e.message)

          false
        end

        def scim_not_found!(message:)
          error!({ with: EE::Gitlab::Scim::NotFound }.merge(detail: message), 404)
        end

        def scim_error!(message:)
          error!({ with: EE::Gitlab::Scim::Error }.merge(detail: message), 409)
        end
      end

      resource :Users do
        before do
          check_group_scim_enabled(find_group(params[:group]))
          check_group_saml_configured
        end

        desc 'Get SAML users' do
          detail 'This feature was introduced in GitLab 11.9.'
        end
        get do
          group = find_group(params[:group])

          scim_error!(message: 'Missing filter params') unless params[:filter]

          parsed_hash = EE::Gitlab::Scim::ParamsParser.new(params).to_hash
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: parsed_hash[:extern_uid])

          status 200

          present identity || {}, with: ::EE::Gitlab::Scim::Users
        end

        desc 'Get a SAML user' do
          detail 'This feature was introduced in GitLab 11.9.'
        end
        get ':id' do
          group = find_group(params[:group])

          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          status 200

          present identity, with: ::EE::Gitlab::Scim::User
        end

        # rubocop: disable CodeReuse/ActiveRecord
        desc 'Updates a SAML user' do
          detail 'This feature was introduced in GitLab 11.9.'
        end
        patch ':id' do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_group(params[:group])

          parser = EE::Gitlab::Scim::ParamsParser.new(params)
          parsed_hash = parser.to_hash
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          updated = if parser.deprovision_user?
                      destroy_identity(identity)
                    elsif parsed_hash[:extern_uid]
                      identity.update(parsed_hash.slice(:extern_uid))
                    else
                      scim_error!(message: 'Email has already been taken') if parsed_hash[:email] &&
                          User.by_any_email(parsed_hash[:email].downcase).where.not(id: identity.user.id).count > 0

                      result = ::Users::UpdateService.new(identity.user,
                                                          parsed_hash.except(:extern_uid, :provider)
                                                            .merge(user: identity.user)).execute

                      result[:status] == :success
                    end

          if updated
            status 204

            {}
          else
            scim_error!(message: "Error updating #{identity.user.name} with #{parsed_hash.inspect}")
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Removes a SAML user' do
          detail 'This feature was introduced in GitLab 11.9.'
        end
        delete ":id" do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_group(params[:group])
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          status 204

          scim_not_found!(message: "Resource #{params[:id]} not found") unless destroy_identity(identity)

          {}
        end
      end
    end
  end
end
