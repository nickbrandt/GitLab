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
          name: :license_scanning_jobs,
          fallback: 0
        },
        sast: {
          name: :sast_jobs
        }
      }.freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :usage_data_counters
        def usage_data_counters
          super + [::Gitlab::UsageCounters::DesignsCounter, ::Gitlab::UsageDataCounters::LicensesList]
        end

        override :uncached_data
        def uncached_data
          return super if ::Feature.disabled?(:usage_activity_by_stage, default_enabled: true)

          time_period = { created_at: 28.days.ago..Time.current }
          usage_activity_by_stage_monthly = usage_activity_by_stage(:usage_activity_by_stage_monthly, time_period)
          super.merge(usage_activity_by_stage).merge(usage_activity_by_stage_monthly)
        end

        override :features_usage_data
        def features_usage_data
          super.merge(features_usage_data_ee)
        end

        def features_usage_data_ee
          {
            elasticsearch_enabled: alt_usage_data { ::Gitlab::CurrentSettings.elasticsearch_search? },
            license_trial_ends_on: alt_usage_data { License.trial_ends_on },
            geo_enabled: alt_usage_data { ::Gitlab::Geo.enabled? }
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

        def security_products_usage
          results = SECURE_PRODUCT_TYPES.each_with_object({}) do |(secure_type, attribs), response|
            response[attribs[:name]] = count(::Ci::Build.where(name: secure_type), fallback: attribs.fetch(:fallback, -1)) # rubocop:disable CodeReuse/ActiveRecord
          end

          # handle license rename https://gitlab.com/gitlab-org/gitlab/issues/8911
          license_scan_count = results.delete(:license_scanning_jobs)
          results[:license_management_jobs] += license_scan_count

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
        def system_usage_data
          super.tap do |usage_data|
            usage_data[:counts].merge!(
              {
                dependency_list_usages_total: ::Gitlab::UsageCounters::DependencyList.usage_totals[:total],
                epics: count(::Epic),
                feature_flags: count(Operations::FeatureFlag),
                geo_nodes: count(::GeoNode),
                ldap_group_links: count(::LdapGroupLink),
                ldap_keys: count(::LDAPKey),
                ldap_users: count(::User.ldap, 'users.id'),
                pod_logs_usages_total: ::Gitlab::UsageCounters::PodLogs.usage_totals[:total],
                projects_enforcing_code_owner_approval: count(::Project.without_deleted.non_archived.requiring_code_owner_approval),
                merge_requests_with_optional_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_optional, :merge_request_id),
                merge_requests_with_required_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_required, :merge_request_id),
                projects_mirrored_with_pipelines_enabled: count(::Project.mirrored_with_enabled_pipelines),
                projects_reporting_ci_cd_back_to_github: count(::GithubService.without_defaults.active),
                projects_with_packages: distinct_count(::Packages::Package, :project_id),
                projects_with_tracing_enabled: count(ProjectTracingSetting),
                status_page_projects: count(::StatusPageSetting.enabled),
                status_page_issues: count(::Issue.on_status_page),
                template_repositories: count(::Project.with_repos_templates) + count(::Project.with_groups_level_repos_templates)
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

        # Source: https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/ping_metrics_to_stage_mapping_data.csv
        def usage_activity_by_stage(key = :usage_activity_by_stage, time_period = {})
          {
            key => {
              configure: usage_activity_by_stage_configure(time_period),
              create: usage_activity_by_stage_create(time_period),
              manage: usage_activity_by_stage_manage(time_period),
              monitor: usage_activity_by_stage_monitor(time_period),
              package: usage_activity_by_stage_package(time_period),
              plan: usage_activity_by_stage_plan(time_period),
              release: usage_activity_by_stage_release(time_period),
              secure: usage_activity_by_stage_secure(time_period),
              verify: usage_activity_by_stage_verify(time_period)
            }
          }
        end

        # Omitted because no user, creator or author associated: `auto_devops_disabled`, `auto_devops_enabled`
        # Omitted because not in use anymore: `gcp_clusters`, `gcp_clusters_disabled`, `gcp_clusters_enabled`
        # rubocop:disable CodeReuse/ActiveRecord
        def usage_activity_by_stage_configure(time_period)
          {
            clusters_applications_cert_managers: cluster_applications_user_distinct_count(::Clusters::Applications::CertManager, time_period),
            clusters_applications_helm: cluster_applications_user_distinct_count(::Clusters::Applications::Helm, time_period),
            clusters_applications_ingress: cluster_applications_user_distinct_count(::Clusters::Applications::Ingress, time_period),
            clusters_applications_knative: cluster_applications_user_distinct_count(::Clusters::Applications::Knative, time_period),
            clusters_management_project: clusters_user_distinct_count(::Clusters::Cluster.with_management_project, time_period),
            clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled, time_period),
            clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled, time_period),
            clusters_platforms_gke: clusters_user_distinct_count(::Clusters::Cluster.gcp_installed.enabled, time_period),
            clusters_platforms_eks: clusters_user_distinct_count(::Clusters::Cluster.aws_installed.enabled, time_period),
            clusters_platforms_user: clusters_user_distinct_count(::Clusters::Cluster.user_provided.enabled, time_period),
            instance_clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled.instance_type, time_period),
            instance_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.instance_type, time_period),
            group_clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled.group_type, time_period),
            group_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.group_type, time_period),
            project_clusters_disabled: clusters_user_distinct_count(::Clusters::Cluster.disabled.project_type, time_period),
            project_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.project_type, time_period),
            projects_slack_notifications_active: distinct_count(::Project.with_slack_service.where(time_period), :creator_id),
            projects_slack_slash_active: distinct_count(::Project.with_slack_slash_commands_service.where(time_period), :creator_id),
            projects_with_prometheus_alerts: distinct_count(::Project.with_prometheus_service.where(time_period), :creator_id)
          }
        end

        # Omitted because no user, creator or author associated: `lfs_objects`, `pool_repositories`, `web_hooks`
        def usage_activity_by_stage_create(time_period)
          {
            deploy_keys: distinct_count(::DeployKey.where(time_period), :user_id),
            keys: distinct_count(::Key.regular_keys.where(time_period), :user_id),
            merge_requests: distinct_count(::MergeRequest.where(time_period), :author_id),
            projects_enforcing_code_owner_approval: distinct_count(::Project.requiring_code_owner_approval.where(time_period), :creator_id),
            merge_requests_with_optional_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_optional.where(time_period), :merge_request_id),
            merge_requests_with_required_codeowners: distinct_count(::ApprovalMergeRequestRule.code_owner_approval_required.where(time_period), :merge_request_id),
            projects_imported_from_github: distinct_count(::Project.github_imported.where(time_period), :creator_id),
            projects_with_repositories_enabled: distinct_count(::Project.with_repositories_enabled.where(time_period),
                                                               :creator_id,
                                                               start: ::User.minimum(:id),
                                                               finish: ::User.maximum(:id)),
            protected_branches: distinct_count(::Project.with_protected_branches.where(time_period), :creator_id, start: ::User.minimum(:id), finish: ::User.maximum(:id)),
            remote_mirrors: distinct_count(::Project.with_remote_mirrors.where(time_period), :creator_id),
            snippets: distinct_count(::Snippet.where(time_period), :author_id),
            suggestions: distinct_count(::Note.with_suggestions.where(time_period),
                                        :author_id,
                                        start: ::User.minimum(:id),
                                        finish: ::User.maximum(:id))
          }
        end

        # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
        def usage_activity_by_stage_manage(time_period)
          {
            events: distinct_count(::Event.where(time_period), :author_id),
            groups: distinct_count(::GroupMember.where(time_period), :user_id),
            ldap_keys: distinct_count(::LDAPKey.where(time_period), :user_id),
            ldap_users: distinct_count(::GroupMember.of_ldap_type.where(time_period), :user_id),
            users_created: count(::User.where(time_period)),
            value_stream_management_customized_group_stages: count(::Analytics::CycleAnalytics::GroupStage.where(custom: true))
          }
        end

        def usage_activity_by_stage_monitor(time_period)
          {
            clusters: distinct_count(::Clusters::Cluster.where(time_period), :user_id),
            clusters_applications_prometheus: cluster_applications_user_distinct_count(::Clusters::Applications::Prometheus, time_period),
            operations_dashboard_default_dashboard: count(::User.active.with_dashboard('operations').where(time_period)),
            operations_dashboard_users_with_projects_added: distinct_count(UsersOpsDashboardProject.joins(:user).merge(::User.active).where(time_period), :user_id),
            projects_prometheus_active: distinct_count(::Project.with_active_prometheus_service.where(time_period), :creator_id),
            projects_with_error_tracking_enabled: distinct_count(::Project.with_enabled_error_tracking.where(time_period), :creator_id),
            projects_with_tracing_enabled: distinct_count(::Project.with_tracing_enabled.where(time_period), :creator_id)
          }
        end

        def usage_activity_by_stage_package(time_period)
          {
            projects_with_packages: distinct_count(::Project.with_packages.where(time_period), :creator_id)
          }
        end

        # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
        # Omitted because too expensive: `epics_deepest_relationship_level`
        # Omitted because of encrypted properties: `projects_jira_cloud_active`, `projects_jira_server_active`
        def usage_activity_by_stage_plan(time_period)
          {
            assignee_lists: distinct_count(::List.assignee.where(time_period), :user_id),
            epics: distinct_count(::Epic.where(time_period), :author_id),
            issues: distinct_count(::Issue.where(time_period), :author_id),
            label_lists: distinct_count(::List.label.where(time_period), :user_id),
            milestone_lists: distinct_count(::List.milestone.where(time_period), :user_id),
            notes: distinct_count(::Note.where(time_period), :author_id),
            projects: distinct_count(::Project.where(time_period), :creator_id),
            projects_jira_active: distinct_count(::Project.with_active_jira_services.where(time_period), :creator_id),
            projects_jira_dvcs_cloud_active: distinct_count(::Project.with_active_jira_services.with_jira_dvcs_cloud.where(time_period), :creator_id),
            projects_jira_dvcs_server_active: distinct_count(::Project.with_active_jira_services.with_jira_dvcs_server.where(time_period), :creator_id),
            service_desk_enabled_projects: distinct_count_service_desk_enabled_projects(time_period),
            service_desk_issues: count(::Issue.service_desk.where(time_period)),
            todos: distinct_count(::Todo.where(time_period), :author_id)
          }
        end

        # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
        def usage_activity_by_stage_release(time_period)
          {
            deployments: distinct_count(::Deployment.where(time_period), :user_id),
            failed_deployments: distinct_count(::Deployment.failed.where(time_period), :user_id),
            projects_mirrored_with_pipelines_enabled: distinct_count(::Project.mirrored_with_enabled_pipelines.where(time_period), :creator_id),
            releases: distinct_count(::Release.where(time_period), :author_id),
            successful_deployments: distinct_count(::Deployment.success.where(time_period), :user_id)
          }
        end

        # Omitted because no user, creator or author associated: `ci_runners`
        def usage_activity_by_stage_verify(time_period)
          {
            ci_builds: distinct_count(::Ci::Build.where(time_period), :user_id),
            ci_external_pipelines: distinct_count(::Ci::Pipeline.external.where(time_period), :user_id),
            ci_internal_pipelines: distinct_count(::Ci::Pipeline.internal.where(time_period), :user_id),
            ci_pipeline_config_auto_devops: distinct_count(::Ci::Pipeline.auto_devops_source.where(time_period), :user_id),
            ci_pipeline_config_repository: distinct_count(::Ci::Pipeline.repository_source.where(time_period), :user_id),
            ci_pipeline_schedules: distinct_count(::Ci::PipelineSchedule.where(time_period), :owner_id),
            ci_pipelines: distinct_count(::Ci::Pipeline.where(time_period), :user_id),
            ci_triggers: distinct_count(::Ci::Trigger.where(time_period), :owner_id),
            clusters_applications_runner: cluster_applications_user_distinct_count(::Clusters::Applications::Runner, time_period),
            projects_reporting_ci_cd_back_to_github: distinct_count(::Project.with_github_service_pipeline_events.where(time_period), :creator_id)
          }
        end

        # Currently too complicated and to get reliable counts for these stats:
        # container_scanning_jobs, dast_jobs, dependency_scanning_jobs, license_management_jobs, sast_jobs
        # Once https://gitlab.com/gitlab-org/gitlab/merge_requests/17568 is merged, this might be doable
        def usage_activity_by_stage_secure(time_period)
          prefix = 'user_'

          results = {
            user_preferences_group_overview_security_dashboard: count(::User.active.group_view_security_dashboard.where(time_period))
          }

          SECURE_PRODUCT_TYPES.each do |secure_type, attribs|
            results["#{prefix}#{attribs[:name]}".to_sym] = distinct_count(::Ci::Build.where(name: secure_type).where(time_period), :user_id, fallback: attribs.fetch(:fallback, -1))
          end

          # handle license rename https://gitlab.com/gitlab-org/gitlab/issues/8911
          combined_license_key = "#{prefix}license_management_jobs".to_sym
          license_scan_count = results.delete("#{prefix}license_scanning_jobs".to_sym)
          results[combined_license_key] += license_scan_count

          results
        end

        private

        def distinct_count_service_desk_enabled_projects(time_period)
          project_creator_id_start = ::User.minimum(:id)
          project_creator_id_finish = ::User.maximum(:id)

          distinct_count(::Project.service_desk_enabled.where(time_period), :creator_id, start: project_creator_id_start, finish: project_creator_id_finish)
        end

        def cluster_applications_user_distinct_count(applications, time_period)
          distinct_count(applications.where(time_period).available.joins(:cluster), 'clusters.user_id')
        end

        def clusters_user_distinct_count(clusters, time_period)
          distinct_count(clusters.where(time_period), :user_id)
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
