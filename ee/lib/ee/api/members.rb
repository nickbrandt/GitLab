# frozen_string_literal: true

module EE
  module API
    module Members
      extend ActiveSupport::Concern

      prepended do
        helpers do
          # rubocop: disable CodeReuse/ActiveRecord
          def retrieve_members(source, *args)
            super.tap do |members|
              members.includes(user: :group_saml_identities) if can_view_group_identity?(source)
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def can_view_group_identity?(members_source)
            can?(current_user, :read_group_saml_identity, members_source)
          end
        end
      end
    end
  end
end
