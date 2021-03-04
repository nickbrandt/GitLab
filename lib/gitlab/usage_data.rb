# frozen_string_literal: true

# When developing usage data metrics use the below usage data interface methods
# unless you have good reasons to implement custom usage data
# See `lib/gitlab/utils/usage_data.rb`
#
# Examples
#   issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
#   active_user_count: count(User.active)
#   alt_usage_data { Gitlab::VERSION }
#   redis_usage_data(Gitlab::UsageDataCounters::WikiPageCounter)
#   redis_usage_data { ::Gitlab::UsageCounters::PodLogs.usage_totals[:total] }
module Gitlab
  class UsageData
    DEPRECATED_VALUE = -1000
    MAX_GENERATION_TIME_FOR_SAAS = 40.hours

    CE_MEMOIZED_VALUES = %i(
        issue_minimum_id
        issue_maximum_id
        project_minimum_id
        project_maximum_id
        user_minimum_id
        user_maximum_id
        unique_visit_service
        deployment_minimum_id
        deployment_maximum_id
        auth_providers
        aggregated_metrics
        recorded_at
      ).freeze

    class << self
      include Gitlab::Utils::UsageData
      include Gitlab::Utils::StrongMemoize

      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) do
          uncached_data
        end
      end

      def uncached_data
        clear_memoized

        with_finished_at(:recording_ce_finished_at) do
          license_usage_data
            .merge(system_usage_data_license)
            .merge(system_usage_data_settings)
            .merge(system_usage_data)
            .merge(system_usage_data_monthly)
            .merge(system_usage_data_weekly)
            .merge(features_usage_data)
            .merge(components_usage_data)
            .merge(object_store_usage_data)
            .merge(topology_usage_data)
            .merge(usage_activity_by_stage)
            .merge(usage_activity_by_stage(:usage_activity_by_stage_monthly, last_28_days_time_period))
            .merge(analytics_unique_visits_data)
            .merge(compliance_unique_visits_data)
            .merge(search_unique_visits_data)
            .merge(redis_hll_counters)
        end
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def license_usage_data
        {
          recorded_at: recorded_at,
          uuid: alt_usage_data { Gitlab::CurrentSettings.uuid },
          hostname: alt_usage_data { Gitlab.config.gitlab.host },
          version: alt_usage_data { Gitlab::VERSION },
          installation_type: alt_usage_data { installation_type },
          active_user_count: count(User.active),
          edition: 'CE'
        }
      end

      def recorded_at
        @recorded_at ||= Time.current
      end

      # rubocop: disable Metrics/AbcSize
      # rubocop: disable CodeReuse/ActiveRecord
      def system_usage_data
        issues_created_manually_from_alerts = count(Issue.with_alert_management_alerts.not_authored_by(::User.alert_bot), start: issue_minimum_id, finish: issue_maximum_id)

        {
          counts: {
            assignee_lists: count(List.assignee),
            boards: count(Board),
            ci_builds: count(::Ci::Build),
            ci_internal_pipelines: count(::Ci::Pipeline.internal),
            ci_external_pipelines: count(::Ci::Pipeline.external),
            ci_pipeline_config_auto_devops: count(::Ci::Pipeline.auto_devops_source),
            ci_pipeline_config_repository: count(::Ci::Pipeline.repository_source),
            ci_runners: count(::Ci::Runner),
            ci_triggers: count(::Ci::Trigger),
            ci_pipeline_schedules: count(::Ci::PipelineSchedule),
            auto_devops_enabled: count(::ProjectAutoDevops.enabled),
            auto_devops_disabled: count(::ProjectAutoDevops.disabled),
            deploy_keys: count(DeployKey),
            # rubocop: disable UsageData/LargeTable:
            deployments: deployment_count(Deployment),
            successful_deployments: deployment_count(Deployment.success),
            failed_deployments: deployment_count(Deployment.failed),
            # rubocop: enable UsageData/LargeTable:
            environments: count(::Environment),
            clusters: count(::Clusters::Cluster),
            clusters_enabled: count(::Clusters::Cluster.enabled),
            project_clusters_enabled: count(::Clusters::Cluster.enabled.project_type),
            group_clusters_enabled: count(::Clusters::Cluster.enabled.group_type),
            instance_clusters_enabled: count(::Clusters::Cluster.enabled.instance_type),
            clusters_disabled: count(::Clusters::Cluster.disabled),
            project_clusters_disabled: count(::Clusters::Cluster.disabled.project_type),
            group_clusters_disabled: count(::Clusters::Cluster.disabled.group_type),
            instance_clusters_disabled: count(::Clusters::Cluster.disabled.instance_type),
            clusters_platforms_eks: count(::Clusters::Cluster.aws_installed.enabled),
            clusters_platforms_gke: count(::Clusters::Cluster.gcp_installed.enabled),
            clusters_platforms_user: count(::Clusters::Cluster.user_provided.enabled),
            clusters_applications_helm: count(::Clusters::Applications::Helm.available),
            clusters_applications_ingress: count(::Clusters::Applications::Ingress.available),
            clusters_applications_cert_managers: count(::Clusters::Applications::CertManager.available),
            clusters_applications_crossplane: count(::Clusters::Applications::Crossplane.available),
            clusters_applications_prometheus: count(::Clusters::Applications::Prometheus.available),
            clusters_applications_runner: count(::Clusters::Applications::Runner.available),
            clusters_applications_knative: count(::Clusters::Applications::Knative.available),
            clusters_applications_elastic_stack: count(::Clusters::Applications::ElasticStack.available),
            clusters_applications_jupyter: count(::Clusters::Applications::Jupyter.available),
            clusters_applications_cilium: count(::Clusters::Applications::Cilium.available),
            clusters_management_project: count(::Clusters::Cluster.with_management_project),
            kubernetes_agents: count(::Clusters::Agent),
            kubernetes_agents_with_token: distinct_count(::Clusters::AgentToken, :agent_id),
            in_review_folder: count(::Environment.in_review_folder),
            grafana_integrated_projects: count(GrafanaIntegration.enabled),
            groups: count(Group),
            issues: count(Issue, start: issue_minimum_id, finish: issue_maximum_id),
            issues_created_from_gitlab_error_tracking_ui: count(SentryIssue),
            issues_with_associated_zoom_link: count(ZoomMeeting.added_to_issue),
            issues_using_zoom_quick_actions: distinct_count(ZoomMeeting, :issue_id),
            issues_with_embedded_grafana_charts_approx: grafana_embed_usage_data,
            issues_created_from_alerts: total_alert_issues,
            issues_created_gitlab_alerts: issues_created_manually_from_alerts,
            issues_created_manually_from_alerts: issues_created_manually_from_alerts,
            incident_issues: count(::Issue.incident, start: issue_minimum_id, finish: issue_maximum_id),
            alert_bot_incident_issues: count(::Issue.authored(::User.alert_bot), start: issue_minimum_id, finish: issue_maximum_id),
            incident_labeled_issues: count(::Issue.with_label_attributes(::IncidentManagement::CreateIncidentLabelService::LABEL_PROPERTIES), start: issue_minimum_id, finish: issue_maximum_id),
            keys: count(Key),
            label_lists: count(List.label),
            lfs_objects: count(LfsObject),
            milestone_lists: count(List.milestone),
            milestones: count(Milestone),
            projects_with_packages: distinct_count(::Packages::Package, :project_id),
            packages: count(::Packages::Package),
            pages_domains: count(PagesDomain),
            pool_repositories: count(PoolRepository),
            projects: count(Project),
            projects_creating_incidents: distinct_count(Issue.incident, :project_id),
            projects_imported_from_github: count(Project.where(import_type: 'github')),
            projects_with_repositories_enabled: count(ProjectFeature.where('repository_access_level > ?', ProjectFeature::DISABLED)),
            projects_with_tracing_enabled: count(ProjectTracingSetting),
            projects_with_error_tracking_enabled: count(::ErrorTracking::ProjectErrorTrackingSetting.where(enabled: true)),
            projects_with_alerts_service_enabled: count(Service.active.where(type: 'AlertsService')),
            projects_with_alerts_created: distinct_count(::AlertManagement::Alert, :project_id),
            projects_with_enabled_alert_integrations: distinct_count(::AlertManagement::HttpIntegration.active, :project_id),
            projects_with_prometheus_alerts: distinct_count(PrometheusAlert, :project_id),
            projects_with_terraform_reports: distinct_count(::Ci::JobArtifact.terraform_reports, :project_id),
            projects_with_terraform_states: distinct_count(::Terraform::State, :project_id),
            protected_branches: count(ProtectedBranch),
            protected_branches_except_default: count(ProtectedBranch.where.not(name: ['main', 'master', Gitlab::CurrentSettings.default_branch_name])),
            releases: count(Release),
            remote_mirrors: count(RemoteMirror),
            personal_snippets: count(PersonalSnippet),
            project_snippets: count(ProjectSnippet),
            suggestions: count(Suggestion),
            terraform_reports: count(::Ci::JobArtifact.terraform_reports),
            terraform_states: count(::Terraform::State),
            todos: count(Todo),
            uploads: count(Upload),
            web_hooks: count(WebHook),
            labels: count(Label),
            merge_requests: count(MergeRequest),
            notes: count(Note)
          }.merge(
            services_usage,
            usage_counters,
            user_preferences_usage,
            ingress_modsecurity_usage,
            container_expiration_policies_usage,
            service_desk_counts
          ).tap do |data|
            data[:snippets] = add(data[:personal_snippets], data[:project_snippets])
          end
        }
      end
      # rubocop: enable Metrics/AbcSize

      def snowplow_event_counts(time_period)
        return {} unless report_snowplow_events?

        {
          promoted_issues: count(
            self_monitoring_project
              .product_analytics_events
              .by_category_and_action('epics', 'promote')
              .where(time_period)
          )
        }
      end

      def system_usage_data_monthly
        {
          counts_monthly: {
            # rubocop: disable UsageData/LargeTable:
            deployments: deployment_count(Deployment.where(last_28_days_time_period)),
            successful_deployments: deployment_count(Deployment.success.where(last_28_days_time_period)),
            failed_deployments: deployment_count(Deployment.failed.where(last_28_days_time_period)),
            # rubocop: enable UsageData/LargeTable:
            packages: count(::Packages::Package.where(last_28_days_time_period)),
            personal_snippets: count(PersonalSnippet.where(last_28_days_time_period)),
            project_snippets: count(ProjectSnippet.where(last_28_days_time_period)),
            projects_with_alerts_created: distinct_count(::AlertManagement::Alert.where(last_28_days_time_period), :project_id)
          }.merge(
            snowplow_event_counts(last_28_days_time_period(column: :collector_tstamp)),
            aggregated_metrics_monthly
          ).tap do |data|
            data[:snippets] = add(data[:personal_snippets], data[:project_snippets])
          end
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def system_usage_data_license
        {
          license: {}
        }
      end

      def system_usage_data_settings
        {
          settings: {
            ldap_encrypted_secrets_enabled: alt_usage_data(fallback: nil) { Gitlab::Auth::Ldap::Config.encrypted_secrets.active? },
            operating_system: alt_usage_data(fallback: nil) { operating_system }
          }
        }
      end

      def system_usage_data_weekly
        {
          counts_weekly: {
          }.merge(
            aggregated_metrics_weekly
          )
        }
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def grafana_embed_usage_data
        count(Issue.joins('JOIN grafana_integrations USING (project_id)')
          .where("issues.description LIKE '%' || grafana_integrations.grafana_url || '%'")
          .where(grafana_integrations: { enabled: true }))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def features_usage_data
        features_usage_data_ce
      end

      def features_usage_data_ce
        {
          instance_auto_devops_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.auto_devops_enabled? },
          container_registry_enabled: alt_usage_data(fallback: nil) { Gitlab.config.registry.enabled },
          dependency_proxy_enabled: Gitlab.config.try(:dependency_proxy)&.enabled,
          gitlab_shared_runners_enabled: alt_usage_data(fallback: nil) { Gitlab.config.gitlab_ci.shared_runners_enabled },
          gravatar_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.gravatar_enabled? },
          ldap_enabled: alt_usage_data(fallback: nil) { Gitlab.config.ldap.enabled },
          mattermost_enabled: alt_usage_data(fallback: nil) { Gitlab.config.mattermost.enabled },
          omniauth_enabled: alt_usage_data(fallback: nil) { Gitlab::Auth.omniauth_enabled? },
          prometheus_enabled: alt_usage_data(fallback: nil) { Gitlab::Prometheus::Internal.prometheus_enabled? },
          prometheus_metrics_enabled: alt_usage_data(fallback: nil) { Gitlab::Metrics.prometheus_metrics_enabled? },
          reply_by_email_enabled: alt_usage_data(fallback: nil) { Gitlab::IncomingEmail.enabled? },
          signup_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.allow_signup? },
          web_ide_clientside_preview_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.web_ide_clientside_preview_enabled? },
          ingress_modsecurity_enabled: Feature.enabled?(:ingress_modsecurity),
          grafana_link_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.grafana_enabled? },
          gitpod_enabled: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.gitpod_enabled? }
        }
      end

      # @return [Hash<Symbol, Integer>]
      def usage_counters
        usage_data_counters.map { |counter| redis_usage_data(counter) }.reduce({}, :merge)
      end

      # @return [Array<#totals>] An array of objects that respond to `#totals`
      def usage_data_counters
        Gitlab::UsageDataCounters.counters
      end

      def components_usage_data
        {
          git: { version: alt_usage_data(fallback: { major: -1 }) { Gitlab::Git.version } },
          gitaly: {
            version: alt_usage_data { Gitaly::Server.all.first.server_version },
            servers: alt_usage_data { Gitaly::Server.count },
            clusters: alt_usage_data { Gitaly::Server.gitaly_clusters },
            filesystems: alt_usage_data(fallback: ["-1"]) { Gitaly::Server.filesystems }
          },
          gitlab_pages: {
            enabled: alt_usage_data(fallback: nil) { Gitlab.config.pages.enabled },
            version: alt_usage_data { Gitlab::Pages::VERSION }
          },
          container_registry_server: {
            vendor: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.container_registry_vendor },
            version: alt_usage_data(fallback: nil) { Gitlab::CurrentSettings.container_registry_version }
          },
          database: {
            adapter: alt_usage_data { Gitlab::Database.adapter_name },
            version: alt_usage_data { Gitlab::Database.version },
            pg_system_id: alt_usage_data { Gitlab::Database.system_id }
          },
          mail: {
            smtp_server: alt_usage_data { ActionMailer::Base.smtp_settings[:address] }
          }
        }
      end

      def object_store_config(component)
        config = alt_usage_data(fallback: nil) do
          Settings[component]['object_store']
        end

        if config
          {
            enabled: alt_usage_data { Settings[component]['enabled'] },
            object_store: {
              enabled: alt_usage_data { config['enabled'] },
              direct_upload: alt_usage_data { config['direct_upload'] },
              background_upload: alt_usage_data { config['background_upload'] },
              provider: alt_usage_data { config['connection']['provider'] }
            }
          }
        else
          {
            enabled: alt_usage_data { Settings[component]['enabled'] }
          }
        end
      end

      def object_store_usage_data
        {
          object_store: {
            artifacts: object_store_config('artifacts'),
            external_diffs: object_store_config('external_diffs'),
            lfs: object_store_config('lfs'),
            uploads: object_store_config('uploads'),
            packages: object_store_config('packages')
          }
        }
      end

      def topology_usage_data
        Gitlab::UsageData::Topology.new.topology_usage_data
      end

      # rubocop: disable UsageData/DistinctCountByLargeForeignKey
      def ingress_modsecurity_usage
        ##
        # This method measures usage of the Modsecurity Web Application Firewall across the entire
        # instance's deployed environments.
        #
        # NOTE: this service is an approximation as it does not yet take into account if environment
        # is enabled and only measures applications installed using GitLab Managed Apps (disregards
        # CI-based managed apps).
        #
        # More details: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28331#note_318621786
        ##

        column = ::Deployment.arel_table[:environment_id]
        {
          ingress_modsecurity_logging: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_enabled.logging), column),
          ingress_modsecurity_blocking: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_enabled.blocking), column),
          ingress_modsecurity_disabled: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_disabled), column),
          ingress_modsecurity_not_installed: distinct_count(successful_deployments_with_cluster(::Clusters::Applications::Ingress.modsecurity_not_installed), column)
        }
      end
      # rubocop: enable UsageData/DistinctCountByLargeForeignKey

      # rubocop: disable CodeReuse/ActiveRecord
      def container_expiration_policies_usage
        results = {}
        start = ::Project.minimum(:id)
        finish = ::Project.maximum(:id)

        results[:projects_with_expiration_policy_disabled] = distinct_count(::ContainerExpirationPolicy.where(enabled: false), :project_id, start: start, finish: finish)
        # rubocop: disable UsageData/LargeTable
        base = ::ContainerExpirationPolicy.active
        # rubocop: enable UsageData/LargeTable
        results[:projects_with_expiration_policy_enabled] = distinct_count(base, :project_id, start: start, finish: finish)

        # rubocop: disable UsageData/LargeTable
        %i[keep_n cadence older_than].each do |option|
          ::ContainerExpirationPolicy.public_send("#{option}_options").keys.each do |value| # rubocop: disable GitlabSecurity/PublicSend
            results["projects_with_expiration_policy_enabled_with_#{option}_set_to_#{value}".to_sym] = distinct_count(base.where(option => value), :project_id, start: start, finish: finish)
          end
        end
        # rubocop: enable UsageData/LargeTable

        results[:projects_with_expiration_policy_enabled_with_keep_n_unset] = distinct_count(base.where(keep_n: nil), :project_id, start: start, finish: finish)
        results[:projects_with_expiration_policy_enabled_with_older_than_unset] = distinct_count(base.where(older_than: nil), :project_id, start: start, finish: finish)

        results
      end

      def services_usage
        # rubocop: disable UsageData/LargeTable:
        Service.available_services_names.each_with_object({}) do |service_name, response|
          response["projects_#{service_name}_active".to_sym] = count(Service.active.where.not(project: nil).where(type: "#{service_name}_service".camelize))
          response["groups_#{service_name}_active".to_sym] = count(Service.active.where.not(group: nil).where(type: "#{service_name}_service".camelize))
          response["templates_#{service_name}_active".to_sym] = count(Service.active.where(template: true, type: "#{service_name}_service".camelize))
          response["instances_#{service_name}_active".to_sym] = count(Service.active.where(instance: true, type: "#{service_name}_service".camelize))
          response["projects_inheriting_#{service_name}_active".to_sym] = count(Service.active.where.not(project: nil).where.not(inherit_from_id: nil).where(type: "#{service_name}_service".camelize))
          response["groups_inheriting_#{service_name}_active".to_sym] = count(Service.active.where.not(group: nil).where.not(inherit_from_id: nil).where(type: "#{service_name}_service".camelize))
        end.merge(jira_usage, jira_import_usage)
        # rubocop: enable UsageData/LargeTable:
      end

      def jira_usage
        # Jira Cloud does not support custom domains as per https://jira.atlassian.com/browse/CLOUD-6999
        # so we can just check for subdomains of atlassian.net
        results = {
          projects_jira_server_active: 0,
          projects_jira_cloud_active: 0,
          projects_jira_dvcs_cloud_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled),
          projects_jira_dvcs_server_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled(cloud: false))
        }

        # rubocop: disable UsageData/LargeTable:
        JiraService.active.includes(:jira_tracker_data).find_in_batches(batch_size: 100) do |services|
          counts = services.group_by do |service|
            # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
            service_url = service.data_fields&.url || (service.properties && service.properties['url'])
            service_url&.include?('.atlassian.net') ? :cloud : :server
          end

          results[:projects_jira_server_active] += counts[:server].size if counts[:server]
          results[:projects_jira_cloud_active] += counts[:cloud].size if counts[:cloud]
        end
        # rubocop: enable UsageData/LargeTable:
        results
      rescue ActiveRecord::StatementInvalid
        { projects_jira_server_active: FALLBACK, projects_jira_cloud_active: FALLBACK }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def jira_import_usage
        # rubocop: disable UsageData/LargeTable
        finished_jira_imports = JiraImportState.finished

        {
          jira_imports_total_imported_count: count(finished_jira_imports),
          jira_imports_projects_count: distinct_count(finished_jira_imports, :project_id),
          jira_imports_total_imported_issues_count: sum(JiraImportState.finished, :imported_issues_count)
        }
        # rubocop: enable UsageData/LargeTable
      end

      # rubocop: disable CodeReuse/ActiveRecord
      # rubocop: disable UsageData/LargeTable
      def successful_deployments_with_cluster(scope)
        scope
          .joins(cluster: :deployments)
          .merge(::Clusters::Cluster.enabled)
          .merge(Deployment.success)
      end
      # rubocop: enable UsageData/LargeTable
      # rubocop: enable CodeReuse/ActiveRecord

      # augmented in EE
      def user_preferences_usage
        {
          user_preferences_user_gitpod_enabled: count(UserPreference.with_user.gitpod_enabled.merge(User.active))
        }
      end

      def merge_requests_users(time_period)
        counter = Gitlab::UsageDataCounters::TrackUniqueEvents

        redis_usage_data do
          counter.count_unique_events(
            event_action: Gitlab::UsageDataCounters::TrackUniqueEvents::MERGE_REQUEST_ACTION,
            date_from: time_period[:created_at].first,
            date_to: time_period[:created_at].last
          )
        end
      end

      def installation_type
        if Rails.env.production?
          Gitlab::INSTALLATION_TYPE
        else
          "gitlab-development-kit"
        end
      end

      def operating_system
        ohai_data = Ohai::System.new.tap do |oh|
          oh.all_plugins(['platform'])
        end.data

        platform = ohai_data['platform']
        platform = 'raspbian' if ohai_data['platform'] == 'debian' && /armv/.match?(ohai_data['kernel']['machine'])

        "#{platform}-#{ohai_data['platform_version']}"
      end

      def last_28_days_time_period(column: :created_at)
        { column => 30.days.ago..2.days.ago }
      end

      # Source: https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/ping_metrics_to_stage_mapping_data.csv
      def usage_activity_by_stage(key = :usage_activity_by_stage, time_period = {})
        {
          key => {
            configure: usage_activity_by_stage_configure(time_period),
            create: usage_activity_by_stage_create(time_period),
            enablement: usage_activity_by_stage_enablement(time_period),
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

      # rubocop: disable CodeReuse/ActiveRecord
      # rubocop: disable UsageData/LargeTable
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
          project_clusters_enabled: clusters_user_distinct_count(::Clusters::Cluster.enabled.project_type, time_period)
        }
      end
      # rubocop: enable UsageData/LargeTable
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_create(time_period)
        {
          deploy_keys: distinct_count(::DeployKey.where(time_period), :user_id),
          keys: distinct_count(::Key.regular_keys.where(time_period), :user_id),
          merge_requests: distinct_count(::MergeRequest.where(time_period), :author_id),
          projects_with_disable_overriding_approvers_per_merge_request: count(::Project.where(time_period.merge(disable_overriding_approvers_per_merge_request: true))),
          projects_without_disable_overriding_approvers_per_merge_request: count(::Project.where(time_period.merge(disable_overriding_approvers_per_merge_request: [false, nil]))),
          remote_mirrors: distinct_count(::Project.with_remote_mirrors.where(time_period), :creator_id),
          snippets: distinct_count(::Snippet.where(time_period), :author_id)
        }.tap do |h|
          if time_period.present?
            h[:merge_requests_users] = merge_requests_users(time_period)
            h.merge!(action_monthly_active_users(time_period))
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Empty placeholder allows this to match the pattern used by other sections
      def usage_activity_by_stage_enablement(time_period)
        {}
      end

      # Omitted because no user, creator or author associated: `campaigns_imported_from_github`, `ldap_group_links`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_manage(time_period)
        {
          events: distinct_count(::Event.where(time_period), :author_id),
          groups: distinct_count(::GroupMember.where(time_period), :user_id),
          users_created: count(::User.where(time_period), start: user_minimum_id, finish: user_maximum_id),
          omniauth_providers: filtered_omniauth_provider_names.reject { |name| name == 'group_saml' },
          user_auth_by_provider: distinct_count_user_auth_by_provider(time_period),
          unique_users_all_imports: unique_users_all_imports(time_period),
          bulk_imports: {
            gitlab: DEPRECATED_VALUE,
            gitlab_v1: count(::BulkImport.where(time_period, source_type: :gitlab))
          },
          project_imports: project_imports(time_period),
          issue_imports: issue_imports(time_period),
          group_imports: group_imports(time_period),

          # Deprecated data to be removed
          projects_imported: {
            total: DEPRECATED_VALUE,
            gitlab_project: DEPRECATED_VALUE,
            gitlab: DEPRECATED_VALUE,
            github: DEPRECATED_VALUE,
            bitbucket: DEPRECATED_VALUE,
            bitbucket_server: DEPRECATED_VALUE,
            gitea: DEPRECATED_VALUE,
            git: DEPRECATED_VALUE,
            manifest: DEPRECATED_VALUE
          },
          issues_imported: {
            jira: DEPRECATED_VALUE,
            fogbugz: DEPRECATED_VALUE,
            phabricator: DEPRECATED_VALUE,
            csv: DEPRECATED_VALUE
          },
          groups_imported: DEPRECATED_VALUE
          # End of deprecated keys
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_monitor(time_period)
        {
          clusters: distinct_count(::Clusters::Cluster.where(time_period), :user_id),
          clusters_applications_prometheus: cluster_applications_user_distinct_count(::Clusters::Applications::Prometheus, time_period),
          operations_dashboard_default_dashboard: count(::User.active.with_dashboard('operations').where(time_period),
                                                        start: user_minimum_id,
                                                        finish: user_maximum_id),
          projects_with_tracing_enabled: distinct_count(::Project.with_tracing_enabled.where(time_period), :creator_id),
          projects_with_error_tracking_enabled: distinct_count(::Project.with_enabled_error_tracking.where(time_period), :creator_id),
          projects_with_incidents: distinct_count(::Issue.incident.where(time_period), :project_id),
          projects_with_alert_incidents: distinct_count(::Issue.incident.with_alert_management_alerts.where(time_period), :project_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_package(time_period)
        {
          projects_with_packages: distinct_count(::Project.with_packages.where(time_period), :creator_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `boards`, `labels`, `milestones`, `uploads`
      # Omitted because too expensive: `epics_deepest_relationship_level`
      # Omitted because of encrypted properties: `projects_jira_cloud_active`, `projects_jira_server_active`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_plan(time_period)
        {
          issues: distinct_count(::Issue.where(time_period), :author_id),
          notes: distinct_count(::Note.where(time_period), :author_id),
          projects: distinct_count(::Project.where(time_period), :creator_id),
          todos: distinct_count(::Todo.where(time_period), :author_id),
          service_desk_enabled_projects: distinct_count_service_desk_enabled_projects(time_period),
          service_desk_issues: count(::Issue.service_desk.where(time_period)),
          projects_jira_active: distinct_count(::Project.with_active_jira_services.where(time_period), :creator_id),
          projects_jira_dvcs_cloud_active: distinct_count(::Project.with_active_jira_services.with_jira_dvcs_cloud.where(time_period), :creator_id),
          projects_jira_dvcs_server_active: distinct_count(::Project.with_active_jira_services.with_jira_dvcs_server.where(time_period), :creator_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `environments`, `feature_flags`, `in_review_folder`, `pages_domains`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_release(time_period)
        {
          deployments: distinct_count(::Deployment.where(time_period), :user_id),
          failed_deployments: distinct_count(::Deployment.failed.where(time_period), :user_id),
          releases: distinct_count(::Release.where(time_period), :author_id),
          successful_deployments: distinct_count(::Deployment.success.where(time_period), :user_id)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Omitted because no user, creator or author associated: `ci_runners`
      # rubocop: disable CodeReuse/ActiveRecord
      def usage_activity_by_stage_verify(time_period)
        {
          ci_builds: distinct_count(::Ci::Build.where(time_period), :user_id),
          ci_external_pipelines: distinct_count(::Ci::Pipeline.external.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_internal_pipelines: distinct_count(::Ci::Pipeline.internal.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_pipeline_config_auto_devops: distinct_count(::Ci::Pipeline.auto_devops_source.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_pipeline_config_repository: distinct_count(::Ci::Pipeline.repository_source.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_pipeline_schedules: distinct_count(::Ci::PipelineSchedule.where(time_period), :owner_id),
          ci_pipelines: distinct_count(::Ci::Pipeline.where(time_period), :user_id, start: user_minimum_id, finish: user_maximum_id),
          ci_triggers: distinct_count(::Ci::Trigger.where(time_period), :owner_id),
          clusters_applications_runner: cluster_applications_user_distinct_count(::Clusters::Applications::Runner, time_period)
        }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Currently too complicated and to get reliable counts for these stats:
      # container_scanning_jobs, dast_jobs, dependency_scanning_jobs, license_management_jobs, sast_jobs, secret_detection_jobs
      # Once https://gitlab.com/gitlab-org/gitlab/merge_requests/17568 is merged, this might be doable
      def usage_activity_by_stage_secure(time_period)
        {}
      end

      def redis_hll_counters
        { redis_hll_counters: ::Gitlab::UsageDataCounters::HLLRedisCounter.unique_events_data }
      end

      def aggregated_metrics_monthly
        {
          aggregated_metrics: aggregated_metrics.monthly_data
        }
      end

      def aggregated_metrics_weekly
        {
          aggregated_metrics: aggregated_metrics.weekly_data
        }
      end

      def analytics_unique_visits_data
        results = ::Gitlab::Analytics::UniqueVisits.analytics_events.each_with_object({}) do |target, hash|
          hash[target] = redis_usage_data { unique_visit_service.unique_visits_for(targets: target) }
        end
        results['analytics_unique_visits_for_any_target'] = redis_usage_data { unique_visit_service.unique_visits_for(targets: :analytics) }
        results['analytics_unique_visits_for_any_target_monthly'] = redis_usage_data { unique_visit_service.unique_visits_for(targets: :analytics, start_date: 4.weeks.ago.to_date, end_date: Date.current) }

        { analytics_unique_visits: results }
      end

      def compliance_unique_visits_data
        results = ::Gitlab::Analytics::UniqueVisits.compliance_events.each_with_object({}) do |target, hash|
          hash[target] = redis_usage_data { unique_visit_service.unique_visits_for(targets: target) }
        end
        results['compliance_unique_visits_for_any_target'] = redis_usage_data { unique_visit_service.unique_visits_for(targets: :compliance) }
        results['compliance_unique_visits_for_any_target_monthly'] = redis_usage_data { unique_visit_service.unique_visits_for(targets: :compliance, start_date: 4.weeks.ago.to_date, end_date: Date.current) }

        { compliance_unique_visits: results }
      end

      def search_unique_visits_data
        events = ::Gitlab::UsageDataCounters::HLLRedisCounter.events_for_category('search')
        results = events.each_with_object({}) do |event, hash|
          hash[event] = redis_usage_data { ::Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: event, start_date: 7.days.ago.to_date, end_date: Date.current) }
        end

        results['search_unique_visits_for_any_target_weekly'] = redis_usage_data { ::Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: events, start_date: 7.days.ago.to_date, end_date: Date.current) }
        results['search_unique_visits_for_any_target_monthly'] = redis_usage_data { ::Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: events, start_date: 4.weeks.ago.to_date, end_date: Date.current) }

        { search_unique_visits: results }
      end

      def action_monthly_active_users(time_period)
        date_range = { date_from: time_period[:created_at].first, date_to: time_period[:created_at].last }

        event_monthly_active_users(date_range)
          .merge!(ide_monthly_active_users(date_range))
      end

      private

      def aggregated_metrics
        @aggregated_metrics ||= ::Gitlab::Usage::Metrics::Aggregates::Aggregate.new(recorded_at)
      end

      def event_monthly_active_users(date_range)
        data = {
          action_monthly_active_users_project_repo: Gitlab::UsageDataCounters::TrackUniqueEvents::PUSH_ACTION,
          action_monthly_active_users_design_management: Gitlab::UsageDataCounters::TrackUniqueEvents::DESIGN_ACTION,
          action_monthly_active_users_wiki_repo: Gitlab::UsageDataCounters::TrackUniqueEvents::WIKI_ACTION,
          action_monthly_active_users_git_write: Gitlab::UsageDataCounters::TrackUniqueEvents::GIT_WRITE_ACTION
        }

        data.each do |key, event|
          data[key] = redis_usage_data { Gitlab::UsageDataCounters::TrackUniqueEvents.count_unique_events(event_action: event, **date_range) }
        end
      end

      def ide_monthly_active_users(date_range)
        counter = Gitlab::UsageDataCounters::EditorUniqueCounter

        {
          action_monthly_active_users_web_ide_edit: redis_usage_data { counter.count_web_ide_edit_actions(**date_range) },
          action_monthly_active_users_sfe_edit: redis_usage_data { counter.count_sfe_edit_actions(**date_range) },
          action_monthly_active_users_snippet_editor_edit: redis_usage_data { counter.count_snippet_editor_edit_actions(**date_range) },
          action_monthly_active_users_sse_edit: redis_usage_data { counter.count_sse_edit_actions(**date_range) },
          action_monthly_active_users_ide_edit: redis_usage_data { counter.count_edit_using_editor(**date_range) }
        }
      end

      def report_snowplow_events?
        self_monitoring_project && Feature.enabled?(:product_analytics_tracking, type: :ops)
      end

      def distinct_count_service_desk_enabled_projects(time_period)
        project_creator_id_start = user_minimum_id
        project_creator_id_finish = user_maximum_id

        distinct_count(::Project.service_desk_enabled.where(time_period), :creator_id, start: project_creator_id_start, finish: project_creator_id_finish) # rubocop: disable CodeReuse/ActiveRecord
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def service_desk_counts
        # rubocop: disable UsageData/LargeTable:
        projects_with_service_desk = ::Project.where(service_desk_enabled: true)
        # rubocop: enable UsageData/LargeTable:
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

      def unique_visit_service
        strong_memoize(:unique_visit_service) do
          ::Gitlab::Analytics::UniqueVisits.new
        end
      end

      def total_alert_issues
        # Remove prometheus table queries once they are deprecated
        # To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/217407.
        add count(Issue.with_alert_management_alerts, start: issue_minimum_id, finish: issue_maximum_id),
          count(::Issue.with_self_managed_prometheus_alert_events, start: issue_minimum_id, finish: issue_maximum_id),
          count(::Issue.with_prometheus_alert_events, start: issue_minimum_id, finish: issue_maximum_id)
      end

      def user_minimum_id
        strong_memoize(:user_minimum_id) do
          ::User.minimum(:id)
        end
      end

      def user_maximum_id
        strong_memoize(:user_maximum_id) do
          ::User.maximum(:id)
        end
      end

      def issue_minimum_id
        strong_memoize(:issue_minimum_id) do
          ::Issue.minimum(:id)
        end
      end

      def issue_maximum_id
        strong_memoize(:issue_maximum_id) do
          ::Issue.maximum(:id)
        end
      end

      def deployment_minimum_id
        strong_memoize(:deployment_minimum_id) do
          ::Deployment.minimum(:id)
        end
      end

      def deployment_maximum_id
        strong_memoize(:deployment_maximum_id) do
          ::Deployment.maximum(:id)
        end
      end

      def project_minimum_id
        strong_memoize(:project_minimum_id) do
          ::Project.minimum(:id)
        end
      end

      def project_maximum_id
        strong_memoize(:project_maximum_id) do
          ::Project.maximum(:id)
        end
      end

      def self_monitoring_project
        Gitlab::CurrentSettings.self_monitoring_project
      end

      def clear_memoized
        CE_MEMOIZED_VALUES.each { |v| clear_memoization(v) }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def cluster_applications_user_distinct_count(applications, time_period)
        distinct_count(applications.where(time_period).available.joins(:cluster), 'clusters.user_id')
      end

      def clusters_user_distinct_count(clusters, time_period)
        distinct_count(clusters.where(time_period), :user_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def omniauth_provider_names
        ::Gitlab.config.omniauth.providers.map(&:name)
      end

      # LDAP provider names are set by customers and could include
      # sensitive info (server names, etc). LDAP providers normally
      # don't appear in omniauth providers but filter to ensure
      # no internal details leak via usage ping.
      def filtered_omniauth_provider_names
        omniauth_provider_names.reject { |name| name.starts_with?('ldap') }
      end

      def deployment_count(relation)
        count relation, start: deployment_minimum_id, finish: deployment_maximum_id
      end

      def project_imports(time_period)
        {
          gitlab_project: projects_imported_count('gitlab_project', time_period),
          gitlab: projects_imported_count('gitlab', time_period),
          github: projects_imported_count('github', time_period),
          bitbucket: projects_imported_count('bitbucket', time_period),
          bitbucket_server: projects_imported_count('bitbucket_server', time_period),
          gitea: projects_imported_count('gitea', time_period),
          git: projects_imported_count('git', time_period),
          manifest: projects_imported_count('manifest', time_period),
          gitlab_migration: count(::BulkImports::Entity.where(time_period).project_entity) # rubocop: disable CodeReuse/ActiveRecord
        }
      end

      def projects_imported_count(from, time_period)
        count(::Project.imported_from(from).where(time_period).where.not(import_type: nil)) # rubocop: disable CodeReuse/ActiveRecord
      end

      def issue_imports(time_period)
        {
          jira: count(::JiraImportState.where(time_period)), # rubocop: disable CodeReuse/ActiveRecord
          fogbugz: projects_imported_count('fogbugz', time_period),
          phabricator: projects_imported_count('phabricator', time_period),
          csv: count(Issues::CsvImport.where(time_period)) # rubocop: disable CodeReuse/ActiveRecord
        }
      end

      def group_imports(time_period)
        {
          group_import: count(::GroupImportState.where(time_period)), # rubocop: disable CodeReuse/ActiveRecord
          gitlab_migration: count(::BulkImports::Entity.where(time_period).group_entity) # rubocop: disable CodeReuse/ActiveRecord
        }
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def unique_users_all_imports(time_period)
        project_imports = distinct_count(::Project.where(time_period).where.not(import_type: nil), :creator_id)
        bulk_imports = distinct_count(::BulkImport.where(time_period), :user_id)
        jira_issue_imports = distinct_count(::JiraImportState.where(time_period), :user_id)
        csv_issue_imports = distinct_count(Issues::CsvImport.where(time_period), :user_id)
        group_imports = distinct_count(::GroupImportState.where(time_period), :user_id)

        add(project_imports, bulk_imports, jira_issue_imports, csv_issue_imports, group_imports)
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable CodeReuse/ActiveRecord
      def distinct_count_user_auth_by_provider(time_period)
        counts = auth_providers_except_ldap.each_with_object({}) do |provider, hash|
          hash[provider] = distinct_count(
            ::AuthenticationEvent.success.for_provider(provider).where(time_period), :user_id)
        end

        if any_ldap_auth_providers?
          counts['ldap'] = distinct_count(
            ::AuthenticationEvent.success.ldap.where(time_period), :user_id
          )
        end

        counts
      end
      # rubocop:enable CodeReuse/ActiveRecord

      # rubocop:disable UsageData/LargeTable
      def auth_providers
        strong_memoize(:auth_providers) do
          ::AuthenticationEvent.providers
        end
      end
      # rubocop:enable UsageData/LargeTable

      def auth_providers_except_ldap
        auth_providers.reject { |provider| provider.starts_with?('ldap') }
      end

      def any_ldap_auth_providers?
        auth_providers.any? { |provider| provider.starts_with?('ldap') }
      end
    end
  end
end

Gitlab::UsageData.prepend_if_ee('EE::Gitlab::UsageData')
