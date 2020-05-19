# frozen_string_literal: true

module Packages
  module Nuget
    module PresenterHelpers
      include ::API::Helpers::RelatedResourcesHelpers

      BLANK_STRING = ''
      EMPTY_ARRAY = [].freeze

      private

      def json_url_for(package)
        path = api_v4_projects_packages_nuget_metadata_package_name_package_version_path(
          {
            id: package.project_id,
            package_name: package.name,
            package_version: package.version,
            format: '.json'
          },
          true
        )

        expose_url(path)
      end

      def archive_url_for(package)
        path = api_v4_projects_packages_nuget_download_package_name_package_version_package_filename_path(
          {
            id: package.project_id,
            package_name: package.name,
            package_version: package.version,
            package_filename: package.package_files.last&.file_name
          },
          true
        )

        expose_url(path)
      end

      def catalog_entry_for(package)
        {
          json_url: json_url_for(package),
          authors: BLANK_STRING,
          dependencies: EMPTY_ARRAY,
          package_name: package.name,
          package_version: package.version,
          archive_url: archive_url_for(package),
          summary: BLANK_STRING,
          tags: tags_for(package),
          metadatum: metadatum_for(package)
        }
      end

      def metadatum_for(package)
        metadatum = package.nuget_metadatum
        return {} unless metadatum

        metadatum.slice(:project_url, :license_url, :icon_url)
                  .compact
      end

      def base_path_for(package)
        api_v4_projects_packages_nuget_path(id: package.project_id)
      end

      def tags_for(package)
        package.tag_names.join(::Packages::Tag::NUGET_TAGS_SEPARATOR)
      end
    end
  end
end
