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

          override :update_group
          def update_group(group)
            params.delete(:file_template_project_id) unless
              group.feature_available?(:custom_file_templates_for_namespace)

            super
          end

          def check_audit_events_available!(group)
            forbidden! unless group.feature_available?(:audit_events)
          end

          def audit_log_finder_params(group)
            audit_log_finder_params = params.slice(:created_after, :created_before)
            audit_log_finder_params.merge(entity_type: group.class.name, entity_id: group.id)
          end
        end

        resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Sync a group with LDAP.'
          post ":id/ldap_sync" do
            not_found! unless ::Gitlab::Auth::LDAP::Config.group_sync_enabled?

            group = find_group!(params[:id])
            authorize! :admin_group, group

            if group.pending_ldap_sync
              ::LdapGroupSyncWorker.perform_async(group.id)
            end

            status 202
          end

          segment ':id/audit_events' do
            before do
              authorize! :admin_group, user_group
              check_audit_events_available!(user_group)
            end

            desc 'Get a list of audit events in this group.' do
              success EE::API::Entities::AuditEvent
            end
            params do
              optional :created_after, type: DateTime, desc: 'Return audit events created after the specified time'
              optional :created_before, type: DateTime, desc: 'Return audit events created before the specified time'

              use :pagination
            end
            get '/' do
              audit_events = AuditLogFinder.new(audit_log_finder_params(user_group)).execute

              present paginate(audit_events), with: EE::API::Entities::AuditEvent
            end

            desc 'Get a specific audit event in this group.' do
              success EE::API::Entities::AuditEvent
            end
            get '/:audit_event_id' do
              audit_log_finder_params = audit_log_finder_params(user_group)
              audit_event = AuditLogFinder.new(audit_log_finder_params.merge(id: params[:audit_event_id])).execute

              not_found!('Audit Event') unless audit_event

              present audit_event, with: EE::API::Entities::AuditEvent
            end
          end
        end
      end
    end
  end
end
