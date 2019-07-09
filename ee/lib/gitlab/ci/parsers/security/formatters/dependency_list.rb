# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class DependencyList
            def initialize(project, sha)
              @commit_path = ::Gitlab::Routing.url_helpers.project_blob_path(project, sha)
            end

            def format(dependency, package_manager, file_path)
              {
                name:     dependency['package']['name'],
                packager: packager(package_manager),
                package_manager: package_manager,
                location: {
                  blob_path: blob_path(file_path),
                  path:      file_path
                },
                version:  dependency['version']
              }
            end

            private

            attr_reader :commit_path

            def blob_path(file_path)
              "#{commit_path}/#{file_path}"
            end

            def packager(package_manager)
              case package_manager
              when 'bundler'
                'Ruby (Bundler)'
              when 'yarn'
                'JavaScript (Yarn)'
              when 'npm'
                'JavaScript (npm)'
              when 'pip'
                'Python (pip)'
              when 'maven'
                'Java (Maven)'
              when 'composer'
                'PHP (Composer)'
              else
                package_manager
              end
            end
          end
        end
      end
    end
  end
end
