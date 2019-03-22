# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class UpdateUserService
        def initialize(identity)
          @identity = identity
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def execute(params)
          parser = EE::Gitlab::Scim::ParamsParser.new(params)
          parsed_hash = parser.to_hash

          if parser.deprovision_user?
            destroy_identity(identity)
          elsif parsed_hash[:extern_uid]
            identity.update(parsed_hash.slice(:extern_uid))
          else
            scim_error!(message: 'Email has already been taken') if email_taken?(parsed_hash[:email], identity)

            result = ::Users::UpdateService.new(identity.user,
                                                parsed_hash.except(:extern_uid, :provider)
                                                  .merge(user: identity.user)).execute

            result[:status] == :success
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
