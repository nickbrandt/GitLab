# frozen_string_literal: true

module EE
  module API
    module Entities
      class GeoNodeStatus < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers
        include ActionView::Helpers::NumberHelper

        expose :geo_node_id

        expose :healthy?, as: :healthy
        expose :health do |node|
          node.healthy? ? 'Healthy' : node.health
        end
        expose :health_status
        expose :missing_oauth_application

        expose :attachments_count
        expose :attachments_synced_count
        expose :attachments_failed_count
        expose :attachments_synced_missing_on_primary_count
        expose :attachments_synced_in_percentage do |node|
          number_to_percentage(node.attachments_synced_in_percentage, precision: 2)
        end

        expose :db_replication_lag_seconds

        expose :lfs_objects_count
        expose :lfs_objects_synced_count
        expose :lfs_objects_failed_count
        expose :lfs_objects_synced_missing_on_primary_count
        expose :lfs_objects_synced_in_percentage do |node|
          number_to_percentage(node.lfs_objects_synced_in_percentage, precision: 2)
        end

        expose :job_artifacts_count
        expose :job_artifacts_synced_count
        expose :job_artifacts_failed_count
        expose :job_artifacts_synced_missing_on_primary_count
        expose :job_artifacts_synced_in_percentage do |node|
          number_to_percentage(node.job_artifacts_synced_in_percentage, precision: 2)
        end

        expose :container_repositories_count
        expose :container_repositories_synced_count
        expose :container_repositories_failed_count
        expose :container_repositories_synced_in_percentage do |node|
          number_to_percentage(node.container_repositories_synced_in_percentage, precision: 2)
        end

        expose :design_repositories_count
        expose :design_repositories_synced_count
        expose :design_repositories_failed_count
        expose :design_repositories_synced_in_percentage do |node|
          number_to_percentage(node.design_repositories_synced_in_percentage, precision: 2)
        end

        expose :projects_count

        expose :repositories_failed_count
        expose :repositories_synced_count
        expose :repositories_synced_in_percentage do |node|
          number_to_percentage(node.repositories_synced_in_percentage, precision: 2)
        end

        expose :wikis_failed_count
        expose :wikis_synced_count
        expose :wikis_synced_in_percentage do |node|
          number_to_percentage(node.wikis_synced_in_percentage, precision: 2)
        end

        expose :repository_verification_enabled

        expose :repositories_checksummed_count
        expose :repositories_checksum_failed_count
        expose :repositories_checksummed_in_percentage do |node|
          number_to_percentage(node.repositories_checksummed_in_percentage, precision: 2)
        end

        expose :wikis_checksummed_count
        expose :wikis_checksum_failed_count
        expose :wikis_checksummed_in_percentage do |node|
          number_to_percentage(node.wikis_checksummed_in_percentage, precision: 2)
        end

        expose :repositories_verification_failed_count
        expose :repositories_verified_count
        expose :repositories_verified_in_percentage do |node|
          number_to_percentage(node.repositories_verified_in_percentage, precision: 2)
        end
        expose :repositories_checksum_mismatch_count

        expose :wikis_verification_failed_count
        expose :wikis_verified_count
        expose :wikis_verified_in_percentage do |node|
          number_to_percentage(node.wikis_verified_in_percentage, precision: 2)
        end
        expose :wikis_checksum_mismatch_count

        expose :repositories_retrying_verification_count
        expose :wikis_retrying_verification_count

        expose :replication_slots_count
        expose :replication_slots_used_count
        expose :replication_slots_used_in_percentage do |node|
          number_to_percentage(node.replication_slots_used_in_percentage, precision: 2)
        end
        expose :replication_slots_max_retained_wal_bytes

        expose :repositories_checked_count
        expose :repositories_checked_failed_count
        expose :repositories_checked_in_percentage do |node|
          number_to_percentage(node.repositories_checked_in_percentage, precision: 2)
        end

        expose :last_event_id
        expose :last_event_timestamp
        expose :cursor_last_event_id
        expose :cursor_last_event_timestamp

        expose :last_successful_status_check_timestamp

        expose :version
        expose :revision

        expose :selective_sync_type

        # Deprecated: remove in API v5. We use selective_sync_type instead now.
        expose :namespaces, using: ::API::Entities::NamespaceBasic

        expose :updated_at

        # We load GeoNodeStatus data in two ways:
        #
        # 1. Directly by asking a Geo node via an API call
        # 2. Via cached state in the database
        #
        # We don't yet cached the state of the shard information in the database, so if
        # we don't have this information omit from the serialization entirely.
        expose :storage_shards, using: StorageShardEntity, if: ->(status, options) do
          status.storage_shards.present?
        end

        expose :storage_shards_match?, as: :storage_shards_match

        expose :_links do
          expose :self do |geo_node_status|
            expose_url api_v4_geo_nodes_status_path(id: geo_node_status.geo_node_id)
          end

          expose :node do |geo_node_status|
            expose_url api_v4_geo_nodes_path(id: geo_node_status.geo_node_id)
          end
        end

        private

        def namespaces
          object.geo_node.namespaces
        end

        def missing_oauth_application
          object.geo_node.missing_oauth_application?
        end
      end
    end
  end
end
