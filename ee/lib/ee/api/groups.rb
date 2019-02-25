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

          override :create_group
          def create_group
            ldap_link_attrs = {
              cn: params.delete(:ldap_cn),
              group_access: params.delete(:ldap_access)
            }

            authenticated_as_admin! if params[:shared_runners_minutes_limit]

            group = super

            # NOTE: add backwards compatibility for single ldap link
            if group.persisted? && ldap_link_attrs[:cn].present?
              group.ldap_group_links.create(
                cn: ldap_link_attrs[:cn],
                group_access: ldap_link_attrs[:group_access]
              )
            end

            group
          end
        end
      end
    end
  end
end
