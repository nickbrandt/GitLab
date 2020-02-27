# frozen_string_literal: true

module EE
  module Gitlab
    module Scim
      class ReprovisionService
        attr_reader :identity

        delegate :user, :group, to: :identity

        DEFAULT_ACCESS = :guest

        def initialize(identity)
          @identity = identity
        end

        def execute
          ScimIdentity.transaction do
            identity.update!(active: true)
            add_member unless existing_member?
          end
        end

        private

        def add_member
          group.add_user(user, DEFAULT_ACCESS)
        end

        def existing_member?
          ::GroupMember.member_of_group?(group, user)
        end
      end
    end
  end
end
