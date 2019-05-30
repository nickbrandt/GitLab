# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependenciesList
          def parse(json_data)
            report_data = JSON.parse!(json_data)

            data = []
            report_data['dependency_files'].each do |file|
              formatter = Formatters::DependenciesList.new(file['path'], file['package_manager'])
              file['dependencies'].each do |dependency|
                data << formatter.format(dependency)
              end
            end
          end
        end
      end
    end
  end
end
