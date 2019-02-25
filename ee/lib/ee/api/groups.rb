# frozen_string_literal: true

module EE
  module API
    module Groups
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :find_groups
          # rubocop: disable CodeReuse/ActiveRecord
          def find_groups(params, parent_id = nil)
            super.preload(:ldap_group_links)
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
