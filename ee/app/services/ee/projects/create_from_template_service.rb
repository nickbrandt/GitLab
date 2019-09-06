# frozen_string_literal: true

module EE
  module Projects
    module CreateFromTemplateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      override :execute
      def execute
        return super unless use_custom_template?

        if subgroup_id && !valid_project_namespace?
          project.errors.add(:namespace, _("is not a descendant of the Group owning the template"))
          return project
        end

        override_params = params.dup
        params[:custom_template] = template_project if template_project

        ::Projects::GitlabProjectsImportService.new(current_user, params, override_params).execute
      end

      private

      def use_custom_template?
        strong_memoize(:use_custom_template) do
          template_name &&
            ::Gitlab::Utils.to_boolean(params.delete(:use_custom_template)) &&
            ::Gitlab::CurrentSettings.custom_project_templates_enabled?
        end
      end

      def template_project
        strong_memoize(:template_project) do
          current_user.available_custom_project_templates(search: template_name, subgroup_id: subgroup_id)
                      .first
        end
      end

      def subgroup_id
        @subgroup_id ||= params.delete(:group_with_project_templates_id).presence
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def valid_project_namespace?
        templates_owner = ::Group.find(subgroup_id).parent

        return false unless templates_owner

        templates_owner.self_and_descendants.exists?(id: project.namespace_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def project
        @project ||= ::Project.new(namespace_id: params[:namespace_id])
      end
    end
  end
end
