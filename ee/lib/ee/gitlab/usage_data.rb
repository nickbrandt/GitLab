# frozen_string_literal: true

module EE
  module Gitlab
    module UsageData
      extend ActiveSupport::Concern

      SECURE_PRODUCT_TYPES = {
        container_scanning: {
          name: :container_scanning_jobs
        },
        dast: {
          name: :dast_jobs
        },
        dependency_scanning: {
          name: :dependency_scanning_jobs
        },
        license_management: {
          name: :license_management_jobs
        },
        license_scanning: {
          name: :license_scanning_jobs
        },
        sast: {
          name: :sast_jobs
        },
        secret_detection: {
          name: :secret_detection_jobs
        }
      }.freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :usage_data_counters
        def usage_data_counters
          super + [
            ::Gitlab::UsageDataCounters::LicensesList,
            ::Gitlab::UsageDataCounters::IngressModsecurityCounter,
            StatusPage::UsageDataCounters::IncidentCounter,
            ::Gitlab::UsageDataCounters::NetworkPolicyCounter
          ]
        end

        override :uncached_data
        def uncached_data
          with_finished_at(:recording_ee_finished_at) do
            super
          end
        end

        override :features_usage_data
        def features_usage_data
          super.merge(features_usage_data_ee)
        end

        def features_usage_data_ee
          {
            elasticsearch_enabled: alt_usage_data(fallback: nil) { ::Gitlab::CurrentSettings.elasticsearch_search? },
            license_trial_ends_on: alt_usage_data(fallback: nil) { License.trial_ends_on },
            geo_enabled: alt_usage_data(fallback: nil) { ::Gitlab::Geo.enabled? }
          }
        end

        override :license_usage_data
        def license_usage_data
          usage_data = super
          license = ::License.current
          usage_data[:edition] =
            if license
              license.edition
            else
              'EE Free'
            end

          if license
            usage_data[:license_md5] = license.md5
            usage_data[:license_id] = license.license_id
            usage_data[:historical_max_users] = ::HistoricalData.max_historical_user_count
            usage_data[:licensee] = license.licensee
            usage_data[:license_user_count] = license.restricted_user_count
            usage_data[:license_starts_at] = license.starts_at
            usage_data[:license_expires_at] = license.expires_at
            usage_data[:license_plan] = license.plan
            usage_data[:license_add_ons] = license.add_ons
            usage_data[:license_trial] = license.trial?
          end

          usage_data
        end

        def requirements_counts
          return {} unless ::License.feature_available?(:requirements)

          {
            requirements_created: count(RequirementsManagement::Requirement)
          }
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def approval_rules_counts
          {
            approval_project_rules: count(ApprovalProjectRule),
            approval_project_rules_with_target_branch: count(ApprovalProjectRulesProtectedBranch, :approval_project_rule_id)
          }
        end

        def service_desk_counts
          projects_with_service_desk = ::Project.where(service_desk_enabled: true)

          {
            service_desk_enabled_projects: count(projects_with_service_desk),
            service_desk_issues: count(
              ::Issue.where(
                project: projects_with_service_desk,
                author: ::User.support_bot,
                confidential: true
              ),
              start: issue_minimum_id,
              finish: issue_maximum_id
            )
          }
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def security_products_usage
          results = SECURE_PRODUCT_TYPES.each_with_object({}) do |(secure_type, attribs), response|
            response[attribs[:name]] = count(::Ci::Build.where(name: secure_type)) # rubocop:disable CodeReuse/ActiveRecord
          end

          # handle license rename https://gitlab.com/gitlab-org/gitlab/issues/8911
          license_scan_count = results.delete(:license_scanning_jobs)
          results[:license_management_jobs] += license_scan_count > 0 ? license_scan_count : 0

          results
        end

        # Note: when adding a preference, check if it's mapped to an attribute of a User model. If so, name
        # the base key part after a corresponding User model attribute, use its possible values as suffix values.
        override :user_preferences_usage
        def user_preferences_usage
          super.tap do |user_prefs_usage|
            user_prefs_usage.merge!(
              user_preferences_group_overview_details: count(::User.active.group_view_details),
              user_preferences_group_overview_security_dashboard: count(::User.active.group_view_security_dashboard)
            )
          end
        end

        def operations_dashboard_usage
          users_with_ops_dashboard_as_default = count(::User.active.with_dashboard('operations'))
          users_with_projects_added = distinct_count(UsersOpsDashboardProject.joins(:user).merge(::User.active), :user_id) # rubocop:disable CodeReuse/ActiveRecord

          {
            operations_dashboard_default_dashboard: users_with_ops_dashboard_as_default,
            operations_dashboard_users_with_projects_added: users_with_projects_added
          }
        end

        override :system_usage_data
        # Rubocop's Metrics/AbcSize metric is disabled for this method as Rubocop
        # determines this method to be too complex while there's no way to make it
        # less "complex" without introducing extra methods (which actually will
        # make things _more_ complex).
        #
        # rubocop: disable Metrics/AbcSize
        def system_usage_data
          super.tap do |usage_data|
            usage_data[:counts].merge!(
              {
                confidential_epics: count(::Epic.confidential),
                dependency_list_usages_total: redis_usage_data { ::Gitlab::UsageCounters::DependencyList.usage_totals[:total] },
                epics: count(::Epic),
                feature_flags: count(Operations::FeatureFlag),
                geo_nodes: count(::GeoNode),
                geo_event_log_max_id: alt_usage_data { Geo::EventLog.maximum(:id) || 0 },
                ldap_group_links: count(::LdapGroupLink),
                issues_with_health_status: count(::Issue.with_health_status, start: issue_minimum_id, finish: issue_maximum_id),
                ldap_keys: count(::LDAPKey),
                ldap_users: count(::User.ldap, 'users.id'),
                pod_logs_usages_total: redis_usage_data { ::Gitlab::UsageCounters::PodLogs.usage_totals[:total] },
                projects_enforcing_code_owner_approval: count(::Project.without_deleted.non_archived.requiring_code_owner_approval),
                merge_requests_with_added_rules: distinct_count(::ApprovalMergeRequestRule.with_added_approval_rules,
                                                                :merge_request_id,
                                                                start: approval_merge_request_rule_minimum_id,
                                                                finish: approval_merge_request_rule_maximum_id),
                merge_requests_with_optional_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_optional, :merge_request_id),
                merge_requests_with_required_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_required, :merge_request_id),
                projects_mirrored_with_pipelines_enabled: count(::Project.mirrored_with_enabled_pipelines),
                projects_reporting_ci_cd_back_to_github: count(::GithubService.without_defaults.active),
                projects_with_packages: distinct_count(::Packages::Package, :project_id),
                projects_with_tracing_enabled: count(ProjectTracingSetting),
                status_page_projects: count(::StatusPage::ProjectSetting.enabled),
                status_page_issues: count(::Issue.on_status_page, start: issue_minimum_id, finish: issue_maximum_id),
                template_repositories: count(::Project.with_repos_templates) + count(::Project.with_groups_level_repos_templates)
              },
              requirements_counts,
              service_desk_counts,
              security_products_usage,
              epics_deepest_relationship_level,
              operations_dashboard_usage)
          end
        end

        override :jira_usage
        def jira_usage
          super.merge(
            projects_jira_dvcs_cloud_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled),
            projects_jira_dvcs_server_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled(cloud: false)),
            projects_jira_issuelist_active: projects_jira_issuelist_active
          )
        end

        def epics_deepest_relationship_level
          { epics_deepest_relationship_level: ::Epic.deepest_relationship_level.to_i }
        end

        # Omitted because no user, creator or author associated: `auto_devops_disabled`, `auto_devops_enabled`
        # Omitted because not in use anymore: `gcp_clusters`, `gcp_clusters_disabled`, `gcp_clusters_enabled`
        # rubocop:disable CodeReuse/ActiveRecord
        override :usage_activity_by_stage_configure
        def usage_activity_by_stage_configure(time_period)
          super.merge({
            projects_slack_notifications_active: distinct_count(::Project.with_slack_service.where(time_period), :creator_id),
            projects_slack_slash_active: distinct_count(::Project.with_slack_slash_commands_service.where(time_period), :creator_id),
            projects_with_prometheus_alerts: distinct_count(::Project.with_prometheus_service.where(time_period), :creator_id)
          })
        end

        # Omitted because no user, creator or author associated: `lfs_objects`, `pool_repositories`, `web_hooks`
        override :usage_activity_by_stage_create
        def usage_activity_by_stage_create(time_period)
          super.merge({
            projects_enforcing_code_owner_approval: distinct_count(::Project.requiring_code_owner_approval.where(time_period), :creator_id),
            merge_requests_with_added_rules: distinct_count(::ApprovalMergeRequestRule.where(time_period).with_added_approval_rules,
                                                            :merge_request_id,
                                                            start: approval_merge_request_rule_minimum_id,
                                                            finish: approval_merge_request_rule_maximum_id),
            merge_requests_with_optional_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_optional.where(time_period), :merge_request_id),
            merge_requests_with_required_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_required.where(time_period), :merge_request_id),
            projects_imported_from_github: distinct_count(::Project.github_imported.where(time_period), :creator_id),
            projects_with_repositories_enabled: distinct_count(::Project.with_repositories_enabled.where(time_period),
                                                               :creator_id,
                                                               start: user_minimum_id,
                                                               finish: user_maximum_id),
            protected_branches: distinct_count(::Project.with_protected_branches.where(time_period),
                                               :creator_id,
                                               start: user_minimum_id,
                                               finish: user_maximum_id),
            suggestions: distinct_count(::Note.with_suggestions.where(time_period),
                                        :author_id,
                                        start: user_minimum_id,
                                        finish: user_maximum_id)
          }, approval_rules_counts)
        end

        # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
        override :usage_activity_by_stage_manage
        def usage_activity_by_stage_manage(time_period)
          super.merge({
            ldap_keys: distinct_count(::LDAPKey.where(time_period), :user_id),
            ldap_users: distinct_count(::GroupMember.of_ldap_type.where(time_period), :user_id),
            value_stream_management_customized_group_stages: count(::Analytics::CycleAnalytics::GroupStage.where(custom: true)),
            projects_with_compliance_framework: count(::ComplianceManagement::ComplianceFramework::ProjectSettings),
            ldap_servers: ldap_available_servers.size,
            ldap_group_sync_enabled: ldap_config_present_for_any_provider?(:group_base),
            ldap_admin_sync_enabled: ldap_config_present_for_any_provider?(:admin_group),
            group_saml_enabled: omniauth_provider_names.include?('group_saml')
          })
        end

        override :usage_activity_by_stage_monitor
        def usage_activity_by_stage_monitor(time_period)
          super.merge({
            operations_dashboard_users_with_projects_added: distinct_count(UsersOpsDashboardProject.joins(:user).merge(::User.active).where(time_period), :user_id),
            projects_prometheus_active: distinct_count(::Project.with_active_prometheus_service.where(time_period), :creator_id),
            projects_with_error_tracking_enabled: distinct_count(::Project.with_enabled_error_tracking.where(time_period), :creator_id),
            projects_with_tracing_enabled: distinct_count(::Project.with_tracing_enabled.where(time_period), :creator_id)
          })
        end

        override :usage_activity_by_stage_package
        def usage_activity_by_stage_package(time_period)
          super.merge({
            projects_with_packages: distinct_count(::Project.with_packages.where(time_period), :creator_id)
          })
        end

        # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
        # Omitted because too expensive: `epics_deepest_relationship_level`
        # Omitted because of encrypted properties: `projects_jira_cloud_active`, `projects_jira_server_active`
        override :usage_activity_by_stage_plan
        def usage_activity_by_stage_plan(time_period)
          super.merge({
            assignee_lists: distinct_count(::List.assignee.where(time_period), :user_id),
            epics: distinct_count(::Epic.where(time_period), :author_id),
            label_lists: distinct_count(::List.label.where(time_period), :user_id),
            milestone_lists: distinct_count(::List.milestone.where(time_period), :user_id),
            projects_jira_active: distinct_count(::Project.with_active_jira_services.where(time_period), :creator_id),
            projects_jira_dvcs_cloud_active: distinct_count(::Project.with_active_jira_services.with_jira_dvcs_cloud.where(time_period), :creator_id),
            projects_jira_dvcs_server_active: distinct_count(::Project.with_active_jira_services.with_jira_dvcs_server.where(time_period), :creator_id),
            service_desk_enabled_projects: distinct_count_service_desk_enabled_projects(time_period),
            service_desk_issues: count(::Issue.service_desk.where(time_period))
          })
        end

        # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
        override :usage_activity_by_stage_release
        def usage_activity_by_stage_release(time_period)
          super.merge({
            projects_mirrored_with_pipelines_enabled: distinct_count(::Project.mirrored_with_enabled_pipelines.where(time_period), :creator_id)
          })
        end

        # Omitted because no user, creator or author associated: `ci_runners`
        override :usage_activity_by_stage_verify
        def usage_activity_by_stage_verify(time_period)
          super.merge({
            projects_reporting_ci_cd_back_to_github: distinct_count(::Project.with_github_service_pipeline_events.where(time_period), :creator_id)
          })
        end

        # Currently too complicated and to get reliable counts for these stats:
        # container_scanning_jobs, dast_jobs, dependency_scanning_jobs, license_management_jobs, sast_jobs, secret_detection_jobs
        # Once https://gitlab.com/gitlab-org/gitlab/merge_requests/17568 is merged, this might be doable
        override :usage_activity_by_stage_secure
        def usage_activity_by_stage_secure(time_period)
          prefix = 'user_'

          results = {
            user_preferences_group_overview_security_dashboard: count(::User.active.group_view_security_dashboard.where(time_period))
          }

          SECURE_PRODUCT_TYPES.each do |secure_type, attribs|
            results["#{prefix}#{attribs[:name]}".to_sym] = distinct_count(::Ci::Build.where(name: secure_type).where(time_period),
                                                                          :user_id,
                                                                          start: user_minimum_id,
                                                                          finish: user_maximum_id)
          end

          results[:"#{prefix}unique_users_all_secure_scanners"] = distinct_count(::Ci::Build.where(name: SECURE_PRODUCT_TYPES.keys).where(time_period), :user_id)

          # handle license rename https://gitlab.com/gitlab-org/gitlab/issues/8911
          combined_license_key = "#{prefix}license_management_jobs".to_sym
          license_scan_count = results.delete("#{prefix}license_scanning_jobs".to_sym)
          results[combined_license_key] += license_scan_count > 0 ? license_scan_count : 0

          super.merge(results)
        end

        private

        def approval_merge_request_rule_minimum_id
          strong_memoize(:approval_merge_request_rule_minimum_id) do
            ::ApprovalMergeRequestRule.minimum(:id)
          end
        end

        def approval_merge_request_rule_maximum_id
          strong_memoize(:approval_merge_request_rule_maximum_id) do
            ::ApprovalMergeRequestRule.maximum(:id)
          end
        end

        def distinct_count_service_desk_enabled_projects(time_period)
          project_creator_id_start = user_minimum_id
          project_creator_id_finish = user_maximum_id

          distinct_count(::Project.service_desk_enabled.where(time_period), :creator_id, start: project_creator_id_start, finish: project_creator_id_finish)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def ldap_config_present_for_any_provider?(configuration_item)
          ldap_available_servers.any? { |server_config| server_config[configuration_item.to_s] }
        end

        def ldap_available_servers
          ::Gitlab::Auth::Ldap::Config.available_servers
        end

        # rubocop:disable CodeReuse/ActiveRecord
        def projects_jira_issuelist_active
          min_id = JiraTrackerData.where(issues_enabled: true).minimum(:service_id)
          max_id = JiraTrackerData.where(issues_enabled: true).maximum(:service_id)

          count(::JiraService.active.includes(:jira_tracker_data).where(jira_tracker_data: { issues_enabled: true }), start: min_id, finish: max_id)
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
