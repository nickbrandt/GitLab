# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class User < Grape::Entity
        expose :schemas
        expose :extern_uid, as: :id
        expose :active
        expose 'name.formatted' do |identity, _options|
          identity.user.name
        end

        present_collection true, :email
        expose :email_user, as: :emails, using: '::EE::Gitlab::Scim::Emails'

        private

        def schemas
          ["urn:ietf:params:scim:schemas:core:2.0:User"]
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
      end
    end
  end
end
