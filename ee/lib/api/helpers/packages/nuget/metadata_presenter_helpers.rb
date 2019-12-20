# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Nuget
        module MetadataPresenterHelpers
          include ::API::Helpers::RelatedResourcesHelpers
          include ::API::Helpers::PackagesHelpers

          BLANK_STRING = ''
          EMPTY_ARRAY = [].freeze

          private

          def json_url_for(package)
            path = api_v4_projects_packages_nuget_metadata_package_name_package_version_path(
              {
                id: package.project.id,
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
                id: package.project.id,
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
              summary: BLANK_STRING
            }
          end

          def base_path_for(package)
            api_v4_projects_packages_nuget_path(id: package.project.id)
          end
        end
      end
    end
  end
end
