# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Create missing PrometheusServices records or sets active attribute to true
    # for all projects which belongs to cluster with Prometheus Application installed.
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

          def self.attributes_for_project(project_id)
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
        end
      end

      def perform(projects_ids)
        ### Reactivate existing services which weren't configured manually
        Migratable::PrometheusService.inactive.managed.where(project_id: projects_ids).update_all(active: true)

        ### create missing services
        insert_into_services(missing_rows(projects_ids))
      end

      private

      def missing_rows(projects_ids)
        leftover_ids = projects_ids - Migratable::PrometheusService.active.where(project_id: projects_ids)
                                        .or(Migratable::PrometheusService.custom_config.where(project_id: projects_ids))
                                        .pluck(:project_id)

        leftover_ids.map do |project_id|
          Migratable::PrometheusService.attributes_for_project(project_id)
        end
      end

      def insert_into_services(rows)
        Gitlab::Database.bulk_insert(Migratable::PrometheusService.table_name,
                                     rows,
                                     disable_quote: [:created_at, :updated_at])
      end
    end
  end
end
