# frozen_string_literal: true

module EE
  module DB
    module SchemaSupport
      extend ActiveSupport::Concern

      prepended do
        EE_IGNORED_FK_COLUMNS = {
          application_settings: %w[slack_app_id snowplow_app_id],
          approvals: %w[user_id],
          approver_groups: %w[target_id],
          approvers: %w[target_id user_id],
          boards: %w[milestone_id],
          draft_notes: %w[discussion_id],
          epics: %w[updated_by_id last_edited_by_id start_date_sourcing_milestone_id due_date_sourcing_milestone_id],
          geo_event_log: %w[hashed_storage_attachments_event_id],
          geo_job_artifact_deleted_events: %w[job_artifact_id],
          geo_lfs_object_deleted_events: %w[lfs_object_id],
          geo_node_statuses: %w[last_event_id cursor_last_event_id],
          geo_nodes: %w[oauth_application_id],
          geo_repository_deleted_events: %w[project_id],
          geo_upload_deleted_events: %w[upload_id model_id],
          ldap_group_links: %w[group_id],
          projects: %w[mirror_user_id],
          slack_integrations: %w[team_id user_id],
          users: %w[email_opted_in_source_id],
          vulnerability_identifiers: %w[external_id],
          vulnerability_scanners: %w[external_id],
          web_hooks: %w[group_id]
        }.with_indifferent_access.freeze

        IGNORED_LIMIT_ENUMS = {
          'SoftwareLicensePolicy' => %w[classification],
          'User' => %w[group_view]
        }.freeze
      end

      def ignored_fk_columns(column)
        super + EE_IGNORED_FK_COLUMNS.fetch(column, [])
      end

      def ignored_limit_enums(model)
        super + IGNORED_LIMIT_ENUMS.fetch(model, [])
      end
    end
  end
end
