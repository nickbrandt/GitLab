# frozen_string_literal: true
module Gitlab
  module Ci
    module Parsers
      module Security
        class ScannedResources
          def scanned_resources_count(job_artifact)
            scanned_resources_sum = 0
            job_artifact.each_blob do |blob|
              report_data = parse_report_json(blob)
              scanned_resources_sum += report_data.fetch('scan', {}).fetch('scanned_resources', []).length
            end
            scanned_resources_sum
          end

          private

          def parse_report_json(blob)
            Gitlab::Json.parse!(blob)
          rescue JSON::ParserError
            {}
          end
        end
      end
    end
  end
end
