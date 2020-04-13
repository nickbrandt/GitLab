# frozen_string_literal: true

module EE
  module ProjectsHelper
    extend ::Gitlab::Utils::Override

    override :sidebar_settings_paths
    def sidebar_settings_paths
      super + %w[
        audit_events#index
        operations#show
      ]
    end

    override :sidebar_repository_paths
    def sidebar_repository_paths
      super + %w(path_locks)
    end

    override :sidebar_operations_paths
    def sidebar_operations_paths
      super + %w[
        tracings
        feature_flags
      ]
    end

    # rubocop: disable Metrics/CyclomaticComplexity
    override :get_project_nav_tabs
    def get_project_nav_tabs(project, current_user)
      nav_tabs = super

      if can?(current_user, :read_project_security_dashboard, @project)
        nav_tabs << :security
        nav_tabs << :security_configuration
      end

      if can?(current_user, :read_dependencies, @project)
        nav_tabs << :dependencies
      end

      if can?(current_user, :read_licenses, project)
        nav_tabs << :licenses
      end

      if can?(current_user, :read_threat_monitoring, project)
        nav_tabs << :threat_monitoring
      end

      if ::Gitlab.config.packages.enabled &&
          project.feature_available?(:packages) &&
          can?(current_user, :read_package, project)
        nav_tabs << :packages
      end

      if can?(current_user, :read_code_review_analytics, project)
        nav_tabs << :code_review
      end

      if can?(current_user, :read_feature_flag, project) && !nav_tabs.include?(:operations)
        nav_tabs << :operations
      end

      if project.feature_available?(:issues_analytics) && can?(current_user, :read_project, project)
        nav_tabs << :issues_analytics
      end

      if project.insights_available?
        nav_tabs << :project_insights
      end

      nav_tabs
    end
    # rubocop: enable Metrics/CyclomaticComplexity

    override :tab_ability_map
    def tab_ability_map
      tab_ability_map = super
      tab_ability_map[:feature_flags] = :read_feature_flag
      tab_ability_map
    end

    override :project_permissions_settings
    def project_permissions_settings(project)
      super.merge(
        packagesEnabled: !!project.packages_enabled
      )
    end

    override :project_permissions_panel_data
    def project_permissions_panel_data(project)
      super.merge(
        packagesAvailable: ::Gitlab.config.packages.enabled && project.feature_available?(:packages),
        packagesHelpPath: help_page_path('user/packages/index')
      )
    end

    override :default_url_to_repo
    def default_url_to_repo(project = @project)
      case default_clone_protocol
      when 'krb5'
        project.kerberos_url_to_repo
      else
        super
      end
    end

    override :extra_default_clone_protocol
    def extra_default_clone_protocol
      if alternative_kerberos_url? && current_user
        "krb5"
      else
        super
      end
    end

    override :sidebar_operations_link_path
    def sidebar_operations_link_path(project = @project)
      super || project_feature_flags_path(project)
    end

    override :remove_project_message
    def remove_project_message(project)
      return super unless project.feature_available?(:adjourned_deletion_for_projects_and_groups)

      date = permanent_deletion_date(Time.now.utc)
      _("Removing a project places it into a read-only state until %{date}, at which point the project will be permanantly removed. Are you ABSOLUTELY sure?") %
        { date: date }
    end

    def permanent_deletion_date(date)
      (date + ::Gitlab::CurrentSettings.deletion_adjourned_period.days).strftime('%F')
    end

    # Given the current GitLab configuration, check whether the GitLab URL for Kerberos is going to be different than the HTTP URL
    def alternative_kerberos_url?
      ::Gitlab.config.alternative_gitlab_kerberos_url?
    end

    def can_change_push_rule?(push_rule, rule)
      return true if push_rule.global?

      can?(current_user, :"change_#{rule}", @project)
    end

    def ci_cd_projects_available?
      ::License.feature_available?(:ci_cd_projects) && import_sources_enabled?
    end

    def first_class_vulnerabilities_available?(project)
      ::Feature.enabled?(:first_class_vulnerabilities, project)
    end

    def merge_pipelines_available?
      return false unless @project.builds_enabled?

      @project.feature_available?(:merge_pipelines)
    end

    def merge_trains_available?
      return false unless @project.builds_enabled?

      @project.feature_available?(:merge_trains)
    end

    def sidebar_security_paths
      %w[
        projects/security/configuration#show
        projects/security/dashboard#index
        projects/security/vulnerabilities#index
        projects/dependencies#index
        projects/licenses#index
        projects/threat_monitoring#show
      ]
    end

    def size_limit_message(project)
      show_lfs = project.lfs_enabled? ? 'including files in LFS' : ''

      "The total size of this project's repository #{show_lfs} will be limited to this size. 0 for unlimited. Leave empty to inherit the group/global value."
    end

    def subscription_message
      return unless ::Gitlab.com?

      ::Gitlab::ExpiringSubscriptionMessage.new(
        subscribable: decorated_subscription,
        signed_in: signed_in?,
        is_admin: can?(current_user, :owner_access, @project),
        namespace: @project.namespace
      ).message
    end

    def decorated_subscription
      SubscriptionPresenter.new(@project.gitlab_subscription)
    end

    override :membership_locked?
    def membership_locked?
      group = @project.group

      return false unless group

      group.membership_lock? || ::Gitlab::CurrentSettings.lock_memberships_to_ldap?
    end

    def group_project_templates_count(group_id)
      allowed_subgroups = current_user.available_subgroups_with_custom_project_templates(group_id)

      ::Project.in_namespace(allowed_subgroups).count
    end

    def project_security_dashboard_config(project, pipeline)
      if pipeline.nil?
        {
          empty_state_svg_path: image_path('illustrations/security-dashboard_empty.svg'),
          security_dashboard_help_path: help_page_path('user/application_security/security_dashboard/index')
        }
      else
        {
          project: { id: project.id, name: project.name },
          project_full_path: project.full_path,
          vulnerabilities_endpoint: project_security_vulnerability_findings_path(project),
          vulnerabilities_summary_endpoint: summary_project_security_vulnerability_findings_path(project),
          vulnerability_feedback_help_path: help_page_path("user/application_security/index", anchor: "interacting-with-the-vulnerabilities"),
          empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
          dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
          security_dashboard_help_path: help_page_path('user/application_security/security_dashboard/index'),
          pipeline_id: pipeline.id,
          user_path: user_url(pipeline.user),
          user_avatar_path: pipeline.user.avatar_url,
          user_name: pipeline.user.name,
          commit_id: pipeline.commit.short_id,
          commit_path: project_commit_url(project, pipeline.commit),
          ref_id: pipeline.ref,
          ref_path: project_commits_url(project, pipeline.ref),
          pipeline_path: pipeline_url(pipeline),
          pipeline_created: pipeline.created_at.to_s(:iso8601),
          has_pipeline_data: "true"
        }.merge(project_vulnerabilities_config(project))
      end
    end

    def project_vulnerabilities_config(project)
      return {} unless first_class_vulnerabilities_available?(project)

      { vulnerabilities_export_endpoint: api_v4_projects_vulnerability_exports_path(id: project.id) }
    end

    def can_create_feedback?(project, feedback_type)
      feedback = Vulnerabilities::Feedback.new(project: project, feedback_type: feedback_type)
      can?(current_user, :create_vulnerability_feedback, feedback)
    end

    def create_vulnerability_feedback_issue_path(project)
      if can_create_feedback?(project, :issue)
        project_vulnerability_feedback_index_path(project)
      end
    end

    def create_vulnerability_feedback_merge_request_path(project)
      if can_create_feedback?(project, :merge_request)
        project_vulnerability_feedback_index_path(project)
      end
    end

    def create_vulnerability_feedback_dismissal_path(project)
      if can_create_feedback?(project, :dismissal)
        project_vulnerability_feedback_index_path(project)
      end
    end

    def any_project_nav_tab?(tabs)
      tabs.any? { |tab| project_nav_tab?(tab) }
    end

    def show_discover_project_security?(project)
      security_feature_available_at = DateTime.new(2019, 11, 1)

      !!current_user &&
        ::Gitlab.com? &&
        current_user.created_at > security_feature_available_at &&
        !project.feature_available?(:security_dashboard) &&
        can?(current_user, :admin_namespace, project.root_ancestor) &&
        current_user.ab_feature_enabled?(:discover_security)
    end

    def settings_operations_available?
      return true if super

      @project.feature_available?(:tracing, current_user) && can?(current_user, :read_environment, @project)
    end

    override :can_import_members?
    def can_import_members?
      super && !membership_locked?
    end
  end
end
