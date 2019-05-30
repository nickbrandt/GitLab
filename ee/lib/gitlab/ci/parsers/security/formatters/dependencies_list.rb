# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class DependenciesList
            attr_reader :path, :package_manager

            def initialize(path, package_manager)
              @path = path
              @package_manager = package_manager
            end

            def format(dependency)
              {
                name:     dependency['package']['name'],
                packager: packager,
                location: {
                  blob_path: blob_path,
                  path: path,
                },
                version:  dependency['version']
              }
            end

            private

            def blob_path
              "/group-name/project-name/blob/deb6f84e91fe4d21daa6b5558c517254ea2668a3/" + path
            end

            def packager
              case package_manager
              when 'bundler'
                'Ruby (Bundler)'
              when 'yarn'
                'JavaScript (Yarn)'
              when 'npm'
                'JavaScript (npm)'
              when 'pypi'
                'Python (PyPI)'
              when 'maven'
                'Java (Maven)'
              else
                'Unknown'
              end
            end
          end
        end
      end
    end
  end
end
