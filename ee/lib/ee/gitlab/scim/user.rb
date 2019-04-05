# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class User < Grape::Entity
        expose :schemas
        expose :extern_uid, as: :id
        expose :active
        expose :email_user, as: :emails, using: '::EE::Gitlab::Scim::Emails'

        expose 'name.formatted' do |identity, _options|
          identity.user.name
        end
        expose :meta do
          expose :resource_type, as: :resourceType
        end
        expose :username, as: :userName do |identity, _options|
          identity.user.username
        end

        private

        DEFAULT_SCHEMA = 'urn:ietf:params:scim:schemas:core:2.0:User'

        def schemas
          [DEFAULT_SCHEMA]
        end

        def active
          # We don't block the user yet when deprovisioning
          # So the user is always active, until the identity link is removed.
          true
        end

        def email_type
          'work'
        end

        def email_primary
          true
        end

        def email_user
          [object.user]
        end

        def resource_type
          'User'
        end
      end
    end
  end
end
