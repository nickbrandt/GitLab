# frozen_string_literal: true

module EE
  module Groups
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        if changes_file_template_project_id?
          check_file_template_project_id_change!
          return false if group.errors.present?
        end

        handle_ip_restriction_deletion

        remove_insight_if_insight_project_absent

        super.tap { |success| log_audit_event if success }
      end

      private

      override :before_assignment_hook
      def before_assignment_hook(group, params)
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        unless current_user&.admin?
          params.delete(:shared_runners_minutes_limit)
          params.delete(:extra_shared_runners_minutes_limit)
        end
      end

      def changes_file_template_project_id?
        return false unless params.key?(:file_template_project_id)

        params[:file_template_project_id] != group.checked_file_template_project_id
      end

      def check_file_template_project_id_change!
        unless can?(current_user, :admin_group, group)
          group.errors.add(:file_template_project_id, 'cannot be changed by you')
          return
        end

        # Clearing the current value is always permitted if you can admin the group
        return unless params[:file_template_project_id].present?

        # Ensure the user can see the new project, avoiding information disclosures
        return if file_template_project_visible?

        group.errors.add(:file_template_project_id, 'is invalid')
      end

      def file_template_project_visible?
        ::ProjectsFinder.new(
          current_user: current_user,
          project_ids_relation: [params[:file_template_project_id]]
        ).execute.exists?
      end

      def remove_insight_if_insight_project_absent
        if params.dig(:insight_attributes, :project_id) == ''
          params[:insight_attributes][:_destroy] = true
          params[:insight_attributes].delete(:project_id)
        end
      end

      def handle_ip_restriction_deletion
        return unless ip_restriction_editable?

        return unless group.ip_restriction.present?

        ip_restriction_params = params[:ip_restriction_attributes]

        return unless ip_restriction_params

        if ip_restriction_params[:range]&.blank?
          ip_restriction_params[:_destroy] = 1
        end
      end

      def ip_restriction_editable?
        return false if group.parent_id.present?

        true
      end

      def log_audit_event
        EE::Audit::GroupChangesAuditor.new(current_user, group).execute
      end
    end
  end
end
