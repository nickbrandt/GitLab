# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ProvisioningService
        include ::Gitlab::Utils::StrongMemoize

        PASSWORD_AUTOMATICALLY_SET = true
        SKIP_EMAIL_CONFIRMATION = false
        DEFAULT_ACCESS = :guest

        def initialize(group, parsed_hash)
          @group = group
          @parsed_hash = parsed_hash.dup
        end

        def execute
          return success_response if existing_member?

          clear_memoization(:identity)

          if user.save && member.errors.empty?
            success_response
          else
            error_response
          end

        rescue => e
          logger.error(error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          error_response(errors: [e.message])
        end

        private

        def success_response
          ProvisioningResponse.new(status: :success, identity: identity)
        end

        def scim_identities_enabled?
          strong_memoize(:scim_identities_enabled) do
            ::EE::Gitlab::Scim::Feature.scim_identities_enabled?(@group)
          end
        end

        def identity_provider
          strong_memoize(:identity_provider) do
            next 'group_scim' if scim_identities_enabled?

            'group_saml'
          end
        end

        def identity
          strong_memoize(:identity) do
            if scim_identities_enabled?
              @group.scim_identities.with_extern_uid(@parsed_hash[:extern_uid]).first
            else
              ::Identity.with_extern_uid(identity_provider, @parsed_hash[:extern_uid]).first
            end
          end
        end

        def user
          @user ||= ::Users::BuildService.new(nil, user_params).execute(skip_authorization: true)
        end

        def error_response(errors: nil)
          errors ||= [user, identity, member].compact.flat_map { |obj| obj.errors.full_messages }
          conflict = errors.any? { |error| error.include?('has already been taken') }

          ProvisioningResponse.new(status: conflict ? :conflict : :error, message: errors.to_sentence)
        rescue => e
          logger.error(error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          ProvisioningResponse.new(status: :error, message: e.message)
        end

        def logger
          ::API::API.logger
        end

        def user_params
          @parsed_hash.tap do |hash|
            hash[:skip_confirmation] = SKIP_EMAIL_CONFIRMATION
            hash[:saml_provider_id] = @group.saml_provider&.id
            hash[:group_id] = @group.id
            hash[:provider] = identity_provider
            hash[:email_confirmation] = hash[:email]
            hash[:username] = valid_username
            hash[:password] = hash[:password_confirmation] = random_password
            hash[:password_automatically_set] = PASSWORD_AUTOMATICALLY_SET
          end
        end

        def random_password
          ::User.random_password
        end

        def valid_username
          clean_username = ::Namespace.clean_path(@parsed_hash[:username])

          Uniquify.new.string(clean_username) { |s| !NamespacePathValidator.valid_path?(s) }
        end

        def member
          strong_memoize(:member) do
            @group.add_user(user, DEFAULT_ACCESS) if user.valid?
          end
        end

        def existing_member?
          identity && ::GroupMember.member_of_group?(@group, identity.user)
        end
      end
    end
  end
end
