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

          def scanned_resources_for_csv(scanned_resources)
            scanned_resources.map do |sr|
              uri = URI.parse(sr['url'] || '')
              OpenStruct.new({
                request_method: sr['method'],
                scheme: uri.scheme,
                host: uri.host,
                port: uri.port,
                path: uri.path,
                query_string: uri.query,
                raw_url: sr['url']
              })
            end
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
