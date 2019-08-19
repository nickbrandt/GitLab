# frozen_string_literal: true

module EE
  module Gitlab
    module UsageData
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :usage_data_counters
        def usage_data_counters
          super + [::Gitlab::UsageCounters::DesignsCounter]
        end

        override :uncached_data
        def uncached_data
          return super unless ::Feature.enabled?(:usage_activity_by_stage, default_enabled: true)

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
        def projects_mirrored_with_pipelines_enabled
          count(::Project.joins(:project_feature).where(
                  mirror: true,
                  mirror_trigger_builds: true,
                  project_features: {
                    builds_access_level: ::ProjectFeature::ENABLED
                  }
          ))
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def service_desk_counts
          return {} unless ::License.feature_available?(:service_desk)

          projects_with_service_desk = ::Project.where(service_desk_enabled: true)

          {
            service_desk_enabled_projects: count(projects_with_service_desk),
            service_desk_issues: count(::Issue.where(
                                         project: projects_with_service_desk,
                                         author: ::User.support_bot,
                                         confidential: true
            ))
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
              group_overview_details: count(::User.active.group_view_details),
              group_overview_security_dashboard: count(::User.active.group_view_security_dashboard)
            )
          end
        end

        def operations_dashboard_usage
          users_with_ops_dashboard_as_default = count(::User.active.with_dashboard('operations'))
          users_with_projects_added = count(UsersOpsDashboardProject.distinct_users(::User.active))

          {
            default_dashboard: users_with_ops_dashboard_as_default,
            users_with_projects_added: users_with_projects_added
          }
        end

        override :system_usage_data
        def system_usage_data
          usage_data = super

          usage_data[:counts] = usage_data[:counts].merge({
            dependency_list_usages_total: ::Gitlab::UsageCounters::DependencyList.usage_totals[:total],
            epics: count(::Epic),
            feature_flags: count(Operations::FeatureFlag),
            geo_nodes: count(::GeoNode),
            incident_issues: count_incident_issues,
            ldap_group_links: count(::LdapGroupLink),
            ldap_keys: count(::LDAPKey),
            ldap_users: count(::User.ldap),
            operations_dashboard: operations_dashboard_usage,
            pod_logs_usages_total: ::Gitlab::UsageCounters::PodLogs.usage_totals[:total],
            projects_enforcing_code_owner_approval: count(::Project.without_deleted.non_archived.requiring_code_owner_approval),
            projects_mirrored_with_pipelines_enabled: projects_mirrored_with_pipelines_enabled,
            projects_reporting_ci_cd_back_to_github: count(::GithubService.without_defaults.active),
            projects_with_packages: count(::Packages::Package.select('distinct project_id')),
            projects_with_prometheus_alerts: count(PrometheusAlert.distinct_projects),
            projects_with_tracing_enabled: count(ProjectTracingSetting)
          }).merge(service_desk_counts)
            .merge(security_products_usage)
            .merge(epics_deepest_relationship_level)

          usage_data
        end

        override :jira_usage
        def jira_usage
          super.merge(
            projects_jira_dvcs_cloud_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled),
            projects_jira_dvcs_server_active: count(ProjectFeatureUsage.with_jira_dvcs_integration_enabled(cloud: false))
          )
        end

        def epics_deepest_relationship_level
          { epics_deepest_relationship_level: ::Epic.deepest_relationship_level }
        end

        def count_incident_issues
          return 0 unless License.feature_available?(:incident_management)

          count(::Issue.authored(::User.alert_bot))
        end

        # Source: https://gitlab.com/gitlab-data/analytics/blob/master/transform/snowflake-dbt/data/ping_metrics_to_stage_mapping_data.csv
        def usage_activity_by_stage
          {
            usage_activity_by_stage: {
              manage: usage_activity_by_stage_manage
            }
          }
        end

        def usage_activity_by_stage_manage
          {
            groups: ::GroupMember.distinct_count_by(:user_id),
            ldap_keys: ::LDAPKey.distinct_count_by(:user_id),
            ldap_users: ::GroupMember.of_ldap_type.distinct_count_by(:user_id)
          }
        end
      end
    end
  end
end
