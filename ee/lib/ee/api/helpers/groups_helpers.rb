# frozen_string_literal: true

module EE
  module API
    module Helpers
      module GroupsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :membership_lock, type: ::Grape::API::Boolean, desc: 'Prevent adding new members to project membership within this group'
            optional :ldap_cn, type: String, desc: 'LDAP Common Name'
            optional :ldap_access, type: Integer, desc: 'A valid access level'
            optional :shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Pipeline minutes quota for this group'
            optional :extra_shared_runners_minutes_limit, type: Integer, desc: '(admin-only) Extra pipeline minutes quota for this group'
            all_or_none_of :ldap_cn, :ldap_access
          end

          params :optional_update_params_ee do
            optional :file_template_project_id, type: Integer, desc: 'The ID of a project to use for custom templates in this group'
          end
        end
      end
    end
  end
end
