# frozen_string_literal: true

module EE
  module GroupsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      before_action :set_allowed_domain, only: [:edit]
    end

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
        params_ee << { insight_attributes: [:id, :project_id, :_destroy] } if current_group&.insights_available?
        params_ee << :file_template_project_id if current_group&.feature_available?(:custom_file_templates_for_namespace)
        params_ee << :custom_project_templates_group_id if current_group&.group_project_template_available?
        params_ee << :ip_restriction_ranges if current_group&.feature_available?(:group_ip_restriction)
        params_ee << { allowed_email_domain_attributes: [:id, :domain] } if current_group&.feature_available?(:group_allowed_email_domains)
        params_ee << :max_pages_size if can?(current_user, :update_max_pages_size)
      end
    end

    def current_group
      @group
    end

    def redirect_show_path
      strong_memoize(:redirect_show_path) do
        case group_view
        when 'security_dashboard'
          helpers.group_security_dashboard_path(group)
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

    def set_allowed_domain
      return if group.allowed_email_domain.present?

      group.build_allowed_email_domain
    end
  end
end
