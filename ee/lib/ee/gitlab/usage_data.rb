# frozen_string_literal: true

module EE
  module Gitlab
    module UsageData
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :usage_data_counters
        def usage_data_counters
          super + [::Gitlab::UsageCounters::DesignsCounter, ::Gitlab::UsageDataCounters::LicensesList]
        end

        override :uncached_data
        def uncached_data
          # The `usage_activity_by_stage` queries are likely to time out on large instances, and are sure
          # to time out on GitLab.com. Since we are mostly interested in gathering these statistics for
          # self hosted instances, prevent them from running on GitLab.com and allow instance maintainers
          # to disable them via a feature flag.
          return super if ::Gitlab.com? || ::Feature.disabled?(:usage_activity_by_stage, default_enabled: true)

          super.merge(usage_activity_by_stage)
        end

        override :features_usage_data
        def features_usage_data
          super.merge(features_usage_data_ee)
        end

        def features_usage_data_ee
          {
            elasticsearch_enabled: ::Gitlab::CurrentSettings.elasticsearch_search?,
            geo_enabled: ::Gitlab::Geo.enabled?
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

        # rubocop: disable CodeReuse/ActiveRecord
        def service_desk_counts
          return {} unless ::License.feature_available?(:service_desk)

          projects_with_service_desk = ::Project.where(service_desk_enabled: true)

          {
            service_desk_enabled_projects: count(projects_with_service_desk),
            service_desk_issues: count(
              ::Issue.where(
                project: projects_with_service_desk,
                author: ::User.support_bot,
                confidential: true
              )
            )
          }
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def security_products_usage
          types = {
            container_scanning: :container_scanning_jobs,
            dast: :dast_jobs,
            dependency_scanning: :dependency_scanning_jobs,
            license_management: :license_management_jobs,
            sast: :sast_jobs
          }

          results = count(::Ci::Build.where(name: types.keys).group(:name), fallback: Hash.new(-1))
          results.each_with_object({}) { |(key, value), response| response[types[key.to_sym]] = value }
        end
        # rubocop: enable CodeReuse/ActiveRecord

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
          users_with_projects_added = count(UsersOpsDashboardProject.distinct_users(::User.active))

          {
            operations_dashboard_default_dashboard: users_with_ops_dashboard_as_default,
            operations_dashboard_users_with_projects_added: users_with_projects_added
          }
        end

        override :system_usage_data
        def system_usage_data
          super.tap do |usage_data|
            usage_data[:counts].merge!({
                                         dependency_list_usages_total: ::Gitlab::UsageCounters::DependencyList.usage_totals[:total],
                                         epics: count(::Epic),
                                         feature_flags: count(Operations::FeatureFlag),
                                         geo_nodes: count(::GeoNode),
                                         incident_issues: count_incident_issues,
                                         ldap_group_links: count(::LdapGroupLink),
                                         ldap_keys: count(::LDAPKey),
                                         ldap_users: count(::User.ldap),
                                         pod_logs_usages_total: ::Gitlab::UsageCounters::PodLogs.usage_totals[:total],
                                         projects_enforcing_code_owner_approval: count(::Project.without_deleted.non_archived.requiring_code_owner_approval),
                                         projects_mirrored_with_pipelines_enabled: count(::Project.mirrored_with_enabled_pipelines),
                                         projects_reporting_ci_cd_back_to_github: count(::GithubService.without_defaults.active),
                                         projects_with_packages: count(::Packages::Package.select('distinct project_id')),
                                         projects_with_prometheus_alerts: count(PrometheusAlert.distinct_projects),
                                         projects_with_tracing_enabled: count(ProjectTracingSetting),
                                         projects_with_alerts_service_enabled: count(AlertsService.active),
                                         template_repositories:  count(::Project.with_repos_templates) + count(::Project.with_groups_level_repos_templates)
                                       },
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
            projects_jira_dvcs_server_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled(cloud: false))
          )
        end

        def epics_deepest_relationship_level
          { epics_deepest_relationship_level: ::Epic.deepest_relationship_level.to_i }
        end

        def count_incident_issues
          return 0 unless License.feature_available?(:incident_management)

          count(::Issue.authored(::User.alert_bot))
        end

        # Source: https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/ping_metrics_to_stage_mapping_data.csv
        def usage_activity_by_stage
          {
            usage_activity_by_stage: {
              configure: usage_activity_by_stage_configure,
              create: usage_activity_by_stage_create,
              manage: usage_activity_by_stage_manage,
              monitor: usage_activity_by_stage_monitor,
              package: usage_activity_by_stage_package,
              plan: usage_activity_by_stage_plan,
              release: usage_activity_by_stage_release,
              secure: usage_activity_by_stage_secure,
              verify: usage_activity_by_stage_verify
            }
          }
        end

        # Omitted because no user, creator or author associated: `auto_devops_disabled`, `auto_devops_enabled`
        # Omitted because not in use anymore: `gcp_clusters`, `gcp_clusters_disabled`, `gcp_clusters_enabled`
        def usage_activity_by_stage_configure
          {
            clusters_applications_cert_managers: ::Clusters::Applications::CertManager.distinct_by_user,
            clusters_applications_helm: ::Clusters::Applications::Helm.distinct_by_user,
            clusters_applications_ingress: ::Clusters::Applications::Ingress.distinct_by_user,
            clusters_applications_knative: ::Clusters::Applications::Knative.distinct_by_user,
            clusters_disabled: ::Clusters::Cluster.disabled.distinct_count_by(:user_id),
            clusters_enabled: ::Clusters::Cluster.enabled.distinct_count_by(:user_id),
            clusters_platforms_gke: ::Clusters::Cluster.gcp_installed.enabled.distinct_count_by(:user_id),
            clusters_platforms_eks: ::Clusters::Cluster.aws_installed.enabled.distinct_count_by(:user_id),
            clusters_platforms_user: ::Clusters::Cluster.user_provided.enabled.distinct_count_by(:user_id),
            group_clusters_disabled: ::Clusters::Cluster.disabled.group_type.distinct_count_by(:user_id),
            group_clusters_enabled: ::Clusters::Cluster.enabled.group_type.distinct_count_by(:user_id),
            project_clusters_disabled: ::Clusters::Cluster.disabled.project_type.distinct_count_by(:user_id),
            project_clusters_enabled: ::Clusters::Cluster.enabled.project_type.distinct_count_by(:user_id),
            projects_slack_notifications_active: ::Project.with_slack_service.distinct_count_by(:creator_id),
            projects_slack_slash_active: ::Project.with_slack_slash_commands_service.distinct_count_by(:creator_id),
            projects_with_prometheus_alerts: ::Project.with_prometheus_service.distinct_count_by(:creator_id)
          }
        end

        # Omitted because no user, creator or author associated: `lfs_objects`, `pool_repositories`, `web_hooks`
        def usage_activity_by_stage_create
          {
            deploy_keys: ::DeployKey.distinct_count_by(:user_id),
            keys: ::Key.regular_keys.distinct_count_by(:user_id),
            merge_requests: ::MergeRequest.distinct_count_by(:author_id),
            projects_enforcing_code_owner_approval: ::Project.requiring_code_owner_approval.distinct_count_by(:creator_id),
            projects_imported_from_github: ::Project.github_imported.distinct_count_by(:creator_id),
            projects_with_repositories_enabled: ::Project.with_repositories_enabled.distinct_count_by(:creator_id),
            protected_branches: ::Project.with_protected_branches.distinct_count_by(:creator_id),
            remote_mirrors: ::Project.with_remote_mirrors.distinct_count_by(:creator_id),
            snippets: ::Snippet.distinct_count_by(:author_id),
            suggestions: ::Note.with_suggestions.distinct_count_by(:author_id)
          }
        end

        # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
        def usage_activity_by_stage_manage
          {
            groups: ::GroupMember.distinct_count_by(:user_id),
            ldap_keys: ::LDAPKey.distinct_count_by(:user_id),
            ldap_users: ::GroupMember.of_ldap_type.distinct_count_by(:user_id)
          }
        end

        def usage_activity_by_stage_monitor
          {
            clusters: ::Clusters::Cluster.distinct_count_by(:user_id),
            clusters_applications_prometheus: ::Clusters::Applications::Prometheus.distinct_by_user,
            operations_dashboard_default_dashboard: count(::User.active.with_dashboard('operations')),
            operations_dashboard_users_with_projects_added: count(UsersOpsDashboardProject.distinct_users(::User.active)),
            projects_prometheus_active: ::Project.with_active_prometheus_service.distinct_count_by(:creator_id),
            projects_with_error_tracking_enabled: ::Project.with_enabled_error_tracking.distinct_count_by(:creator_id),
            projects_with_tracing_enabled: ::Project.with_tracing_enabled.distinct_count_by(:creator_id)
          }
        end

        def usage_activity_by_stage_package
          {
            projects_with_packages: ::Project.with_packages.distinct_count_by(:creator_id)
          }
        end

        # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
        # Omitted because too expensive: `epics_deepest_relationship_level`
        # Omitted because of encrypted properties: `projects_jira_cloud_active`, `projects_jira_server_active`
        def usage_activity_by_stage_plan
          {
            assignee_lists: ::List.assignee.distinct_count_by(:user_id),
            epics: ::Epic.distinct_count_by(:author_id),
            issues: ::Issue.distinct_count_by(:author_id),
            label_lists: ::List.label.distinct_count_by(:user_id),
            milestone_lists: ::List.milestone.distinct_count_by(:user_id),
            notes: ::Note.distinct_count_by(:author_id),
            projects: ::Project.distinct_count_by(:creator_id),
            projects_jira_active: ::Project.with_active_jira_services.distinct_count_by(:creator_id),
            projects_jira_dvcs_cloud_active: ::Project.with_active_jira_services.with_jira_dvcs_cloud.distinct_count_by(:creator_id),
            projects_jira_dvcs_server_active: ::Project.with_active_jira_services.with_jira_dvcs_server.distinct_count_by(:creator_id),
            service_desk_enabled_projects: ::Project.with_active_services.service_desk_enabled.distinct_count_by(:creator_id),
            service_desk_issues: ::Issue.service_desk.distinct_count_by,
            todos: ::Todo.distinct_count_by(:author_id)
          }
        end

        # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
        def usage_activity_by_stage_release
          {
            deployments: ::Deployment.distinct_count_by(:user_id),
            failed_deployments: ::Deployment.failed.distinct_count_by(:user_id),
            projects_mirrored_with_pipelines_enabled: ::Project.mirrored_with_enabled_pipelines.distinct_count_by(:creator_id),
            releases: ::Release.distinct_count_by(:author_id),
            successful_deployments: ::Deployment.success.distinct_count_by(:user_id)
          }
        end

        # Omitted because no user, creator or author associated: `ci_runners`
        def usage_activity_by_stage_verify
          {
            ci_builds: ::Ci::Build.distinct_count_by(:user_id),
            ci_external_pipelines: ::Ci::Pipeline.external.distinct_count_by(:user_id),
            ci_internal_pipelines: ::Ci::Pipeline.internal.distinct_count_by(:user_id),
            ci_pipeline_config_auto_devops: ::Ci::Pipeline.auto_devops_source.distinct_count_by(:user_id),
            ci_pipeline_config_repository: ::Ci::Pipeline.repository_source.distinct_count_by(:user_id),
            ci_pipeline_schedules: ::Ci::PipelineSchedule.distinct_count_by(:owner_id),
            ci_pipelines: ::Ci::Pipeline.distinct_count_by(:user_id),
            ci_triggers: ::Ci::Trigger.distinct_count_by(:owner_id),
            clusters_applications_runner: ::Clusters::Applications::Runner.distinct_by_user,
            projects_reporting_ci_cd_back_to_github: ::Project.with_github_service_pipeline_events.distinct_count_by(:creator_id)
          }
        end

        # Currently too complicated and to get reliable counts for these stats:
        # container_scanning_jobs, dast_jobs, dependency_scanning_jobs, license_management_jobs, sast_jobs
        # Once https://gitlab.com/gitlab-org/gitlab/merge_requests/17568 is merged, this might be doable
        def usage_activity_by_stage_secure
          {
            user_preferences_group_overview_security_dashboard: count(::User.active.group_view_security_dashboard)
          }
        end
      end
    end
  end
end
