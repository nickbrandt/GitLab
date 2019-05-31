# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class DependencyList
            attr_reader :commit_path

            def initialize(commit_path)
              @commit_path = commit_path
            end

            def format(dependency, package_manager, file_path)
              {
                name:     dependency['package']['name'],
                packager: packager(package_manager),
                location: {
                  blob_path: blob_path(file_path),
                  path: file_path
                },
                version:  dependency['version']
              }
            end

            private

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
                'Unknown'
              end
            end
          end
        end
      end
    end
  end
end
