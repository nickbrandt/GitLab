# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyList
          def parse!(json_data, report, commit_path)
            report_data = JSON.parse!(json_data)

            formatter = Formatters::DependencyList.new(commit_path)
            report_data['dependency_files']&.each do |file|
              file['dependencies'].each do |dependency|
                report.add_dependency(formatter.format(dependency, file['package_manager'], trim_path(file['path'])))
              end
            end
          end

          private

          def trim_path(path)
            path.sub(/(.*)\//, '')
          end
        end
      end
    end
  end
end
