# frozen_string_literal: true

module EE
  module GroupsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :render_show_html
    def render_show_html
      if redirect_show_path
        redirect_to redirect_show_path, status: :temporary_redirect
      else
        super
      end
    end

    def group_params_attributes
      super + group_params_ee
    end

    private

    def group_params_ee
      [
        :membership_lock,
        :repository_size_limit
      ].tap do |params_ee|
        params_ee << { insight_attributes: :project_id } if ::Feature.enabled?(:group_insights) && current_group&.feature_available?(:insights)
        params_ee << :project_creation_level if current_group&.feature_available?(:project_creation_level)
        params_ee << :file_template_project_id if current_group&.feature_available?(:custom_file_templates_for_namespace)
        params_ee << :custom_project_templates_group_id if License.feature_available?(:custom_project_templates)
      end
    end

    def current_group
      @group
    end

    def redirect_show_path
      strong_memoize(:redirect_show_path) do
        case group_view
        when 'security_dashboard'
          helpers.group_security_dashboard_path(group) if ::Feature.enabled?(:group_overview_security_dashboard)
        else
          nil
        end
      end
    end

    def group_view
      current_user&.group_view || default_group_view
    end

    def default_group_view
      EE::User::DEFAULT_GROUP_VIEW
    end
  end
end
