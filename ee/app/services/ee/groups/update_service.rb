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

        return false unless valid_path_change_with_npm_packages?

        handle_changes

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

        insight_project_id = params.dig(:insight_attributes, :project_id)
        if insight_project_id
          group_projects = ::GroupProjectsFinder.new(group: group, current_user: current_user, options: { only_owned: true, include_subgroups: true }).execute
          params.delete(:insight_attributes) unless group_projects.exists?(insight_project_id) # rubocop:disable CodeReuse/ActiveRecord
        end

        super
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

      def handle_changes
        handle_allowed_domain_deletion
        handle_ip_restriction_update
      end

      def handle_ip_restriction_update
        comma_separated_ranges = params.delete(:ip_restriction_ranges)

        return if comma_separated_ranges.nil?

        IpRestrictions::UpdateService.new(group, comma_separated_ranges).execute
      end

      def associations_editable?
        return false if group.parent_id.present?

        true
      end

      def handle_allowed_domain_deletion
        return unless associations_editable?
        return unless group.allowed_email_domain.present?
        return unless allowed_domain_params

        if allowed_domain_params[:domain]&.blank?
          allowed_domain_params[:_destroy] = 1
        end
      end

      def valid_path_change_with_npm_packages?
        return true unless group.packages_feature_available?
        return true if params[:path].blank?
        return true if !group.has_parent? && group.path == params[:path]

        npm_packages = Packages::GroupPackagesFinder.new(current_user, group, package_type: :npm).execute
        if npm_packages.exists?
          group.errors.add(:path, s_('GroupSettings|cannot change when group contains projects with NPM packages'))
          return
        end

        true
      end

      def allowed_domain_params
        @allowed_domain_params ||= params[:allowed_email_domain_attributes]
      end

      def log_audit_event
        EE::Audit::GroupChangesAuditor.new(current_user, group).execute
      end
    end
  end
end
