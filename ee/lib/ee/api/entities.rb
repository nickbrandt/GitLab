# frozen_string_literal: true

module EE
  module API
    module Entities
      module ProtectedBranch
        extend ActiveSupport::Concern

        prepended do
          expose :unprotect_access_levels, using: ::API::Entities::ProtectedRefAccess
          expose :code_owner_approval_required
        end
      end

      module IssueBasic
        extend ActiveSupport::Concern

        prepended do
          expose :weight, if: ->(issue, _) { issue.supports_weight? }
        end
      end

      ########################
      # EE-specific entities #
      ########################
      module DesignManagement
        class Design < Grape::Entity
          expose :id
          expose :project_id
          expose :filename
          expose :image_url do |design|
            ::Gitlab::UrlBuilder.build(design)
          end
        end
      end

      module Nuget
        class ServiceIndex < Grape::Entity
          expose :version
          expose :resources
        end

        class PackageMetadataCatalogEntry < Grape::Entity
          expose :json_url, as: :@id
          expose :authors
          expose :dependencies, as: :dependencyGroups
          expose :package_name, as: :id
          expose :package_version, as: :version
          expose :archive_url, as: :packageContent
          expose :summary
        end

        class PackageMetadata < Grape::Entity
          expose :json_url, as: :@id
          expose :archive_url, as: :packageContent
          expose :catalog_entry, as: :catalogEntry, using: EE::API::Entities::Nuget::PackageMetadataCatalogEntry
        end

        class PackagesMetadataItem < Grape::Entity
          expose :json_url, as: :@id
          expose :lower_version, as: :lower
          expose :upper_version, as: :upper
          expose :packages_count, as: :count
          expose :packages, as: :items, using: EE::API::Entities::Nuget::PackageMetadata
        end

        class PackagesMetadata < Grape::Entity
          expose :count
          expose :items, using: EE::API::Entities::Nuget::PackagesMetadataItem
        end

        class PackagesVersions < Grape::Entity
          expose :versions
        end

        class SearchResultVersion < Grape::Entity
          expose :json_url, as: :@id
          expose :version
          expose :downloads
        end

        class SearchResult < Grape::Entity
          expose :type, as: :@type
          expose :authors
          expose :name, as: :id
          expose :name, as: :title
          expose :summary
          expose :total_downloads, as: :totalDownloads
          expose :verified
          expose :version
          expose :versions, using: EE::API::Entities::Nuget::SearchResultVersion
        end

        class SearchResults < Grape::Entity
          expose :total_count, as: :totalHits
          expose :data, using: EE::API::Entities::Nuget::SearchResult
        end
      end

      module Analytics
        module CodeReview
          class MergeRequest < ::API::Entities::MergeRequestSimple
            expose :milestone, using: ::API::Entities::Milestone
            expose :author, using: ::API::Entities::UserBasic
            expose :approved_by_users, as: :approved_by, using: ::API::Entities::UserBasic
            expose :notes_count do |mr|
              if options[:issuable_metadata]
                # Avoids an N+1 query when metadata is included
                options[:issuable_metadata][mr.id].user_notes_count
              else
                mr.notes.user.count
              end
            end
            expose :review_time do |mr|
              time = mr.metrics.review_time

              next unless time

              (time / ActiveSupport::Duration::SECONDS_PER_HOUR).floor
            end
            expose :diff_stats

            private

            # rubocop: disable CodeReuse/ActiveRecord
            def diff_stats
              result = {
                additions: object.diffs.diff_files.sum(&:added_lines),
                deletions: object.diffs.diff_files.sum(&:removed_lines),
                commits_count: object.commits_count
              }
              result[:total] = result[:additions] + result[:deletions]
              result
            end
            # rubocop: enable CodeReuse/ActiveRecord
          end
        end

        module GroupActivity
          class IssuesCount < Grape::Entity
            expose :issues_count
          end

          class MergeRequestsCount < Grape::Entity
            expose :merge_requests_count
          end
        end
      end
    end
  end
end
