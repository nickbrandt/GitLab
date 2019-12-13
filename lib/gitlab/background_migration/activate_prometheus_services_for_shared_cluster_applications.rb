# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Description of Gitlab::BackgroundMigration::ActivatePrometheusServicesForSharedClusterApplications class
    # It is an implementation of https://docs.gitlab.com/ee/development/background_migrations.html
    # It accepts array of projects records ids, and for related service records either updates active attribute
    # or create new records with default values
    class ActivatePrometheusServicesForSharedClusterApplications
      module Migratable
        # Migration model namespace isolated from application code.
        class PrometheusService < ActiveRecord::Base
          self.table_name = 'services'

          default_scope { where("services.type = 'PrometheusService'") }

          scope :managed, -> { where("services.properties = '{}'") }
          scope :custom_config, -> { where("services.properties != '{}'") }
          scope :active, -> { where("services.active = TRUE") }
          scope :inactive, -> { where("services.active = FALSE") }
        end
      end

      def perform(projects_ids)
        ### Reactivate existing services which weren't configured manually
        Migratable::PrometheusService.inactive.managed.where(project_id: projects_ids).update_all(active: true)

        ### create missing services
        left_over_ids = projects_ids - Migratable::PrometheusService.active.where(project_id: projects_ids)
                                         .or(Migratable::PrometheusService.custom_config.where(project_id: projects_ids))
                                         .pluck(:project_id)

        insert_into_services(left_over_ids.map(&method(:values_for_prometheus_service)))
      end

      private

      def values_for_prometheus_service(project_id)
        {
            project_id: project_id,
            active: true,
            properties: '{}',
            type: 'PrometheusService',
            template: false,
            push_events: true,
            issues_events: true,
            merge_requests_events: true,
            tag_push_events: true,
            note_events: true,
            category: 'monitoring',
            default: false,
            wiki_page_events: true,
            pipeline_events: true,
            confidential_issues_events: true,
            commit_events: true,
            job_events: true,
            confidential_note_events: true,
            deployment_events: false,
            created_at: 'NOW()',
            updated_at: 'NOW()'
        }
      end

      def insert_into_services(rows)
        Gitlab::Database.bulk_insert(Migratable::PrometheusService.table_name,
                                     rows,
                                     disable_quote: [:created_at, :updated_at])
      end
    end
  end
end
