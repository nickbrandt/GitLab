# frozen_string_literal: true

module EE
  module Projects
    module CreateFromTemplateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :template_project_id, :subgroup_id

      override :initialize
      def initialize(user, params)
        super

        @template_project_id = @params.delete(:template_project_id).to_i if @params[:template_project_id].present?
        @subgroup_id = @params.delete(:group_with_project_templates_id).presence
      end

      override :execute
      def execute
        return super unless use_custom_template?
        return project unless validate_group_template!

        override_params = params.dup
        params[:custom_template] = template_project if template_project

        ::Projects::GitlabProjectsImportService.new(current_user, params, override_params).execute
      end

      private

      def validate_group_template!
        if subgroup_id && !valid_project_namespace?
          project.errors.add(:namespace, _("is not a descendant of the Group owning the template"))
          return false
        end

        return true if template_project.present?

        if template_project_id.present?
          project.errors.add(:template_project_id,
                             _("%{template_project_id} is unknown or invalid" % { template_project_id: template_project_id }))
        else
          project.errors.add(:template_name, _("'%{template_name}' is unknown or invalid" % { template_name: template_name }))
        end

        false
      end

      def use_custom_template?
        strong_memoize(:use_custom_template) do
          template_requested? &&
            ::Gitlab::Utils.to_boolean(params.delete(:use_custom_template)) &&
            ::Gitlab::CurrentSettings.custom_project_templates_enabled?
        end
      end

      def template_project
        strong_memoize(:template_project) do
          templates =
            if template_project_id.present?
              current_user.available_custom_project_templates(project_id: template_project_id, subgroup_id: subgroup_id)
            else
              current_user.available_custom_project_templates(search: template_name, subgroup_id: subgroup_id)
            end

          templates.first
        end
      end

      def template_requested?
        template_name.present? || template_project_id.is_a?(Integer)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def valid_project_namespace?
        templates_owner = ::Group.find(subgroup_id).parent

        return false unless templates_owner

        templates_owner.self_and_descendants.exists?(id: project.namespace_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
