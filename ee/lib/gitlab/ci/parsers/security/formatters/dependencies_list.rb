# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class DependenciesList
            attr_reader :path, :package_manager, :commit_path

            def initialize(package_manager, file_path, commit_path)
              @path = file_path
              @package_manager = package_manager
              @commit_path = commit_path
            end

            def format(dependency)
              {
                name:     dependency['package']['name'],
                packager: packager,
                location: {
                  blob_path: blob_path,
                  path: file_path
                },
                version:  dependency['version']
              }
            end

            private

            def blob_path
              commit_path + file_path
            end

            def packager
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
                'Unknown'
              end
            end
          end
        end
      end
    end
  end
end
