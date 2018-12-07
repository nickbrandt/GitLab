# frozen_string_literal: true

module EE
  module Projects
    module CreateService
      extend ::Gitlab::Utils::Override
      include ValidatesClassificationLabel

      override :execute
      def execute
        limit = params.delete(:repository_size_limit)
        mirror = ::Gitlab::Utils.to_boolean(params.delete(:mirror))
        mirror_user_id = current_user.id if mirror
        mirror_trigger_builds = params.delete(:mirror_trigger_builds)
        ci_cd_only = ::Gitlab::Utils.to_boolean(params.delete(:ci_cd_only))
        group_with_project_templates_id = params.delete(:group_with_project_templates_id) if params[:template_name].blank?

        project = super do |project|
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

          if mirror && can?(current_user, :admin_mirror, project)
            project.mirror = mirror unless mirror.nil?
            project.mirror_trigger_builds = mirror_trigger_builds unless mirror_trigger_builds.nil?
            project.mirror_user_id = mirror_user_id
          end

          validate_classification_label(project, :external_authorization_classification_label)
          validate_namespace_used_with_template(project, group_with_project_templates_id)
        end

        if project&.persisted?
          setup_ci_cd_project if ci_cd_only

          log_geo_event(project)
          log_audit_event(project)
        end

        project
      end

      private

      def log_geo_event(project)
        ::Geo::RepositoryCreatedEventStore.new(project).create!
      end

      override :after_create_actions
      def after_create_actions
        super

        create_predefined_push_rule

        project.group&.refresh_members_authorized_projects
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create_predefined_push_rule
        return unless project.feature_available?(:push_rules)

        predefined_push_rule = PushRule.find_by(is_sample: true)

        if predefined_push_rule
          push_rule = predefined_push_rule.dup.tap { |gh| gh.is_sample = false }
          project.push_rule = push_rule
        end
      end

      # When using a project template from a Group, the new project can only be created
      # under the top level group or any subgroup
      def validate_namespace_used_with_template(project, group_with_project_templates_id)
        return unless project.group

        subgroup_with_templates_id = group_with_project_templates_id || params[:group_with_project_templates_id]
        return if subgroup_with_templates_id.blank?

        templates_owner = ::Group.find(subgroup_with_templates_id)

        unless templates_owner.self_and_hierarchy.exists?(id: project.namespace_id)
          project.errors.add(:namespace, _("is out of the hierarchy of the Group owning the template"))
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def setup_ci_cd_project
        return unless ::License.feature_available?(:ci_cd_projects)

        ::CiCd::SetupProject.new(project, current_user).execute
      end

      def log_audit_event(project)
        ::AuditEventService.new(
          current_user,
          project,
          action: :create
        ).for_project.security_event
      end
    end
  end
end
