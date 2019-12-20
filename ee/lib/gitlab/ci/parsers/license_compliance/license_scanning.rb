# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module LicenseCompliance
        class LicenseScanning
          LicenseScanningParserError = Class.new(Gitlab::Ci::Parsers::ParserError)
          DEFAULT_VERSION = '1.0'
          PARSERS = { '1' => V1, '2' => V2 }.freeze

          def parse!(json_data, report)
            json = JSON.parse(json_data, symbolize_names: true)
            report.version = json[:version].presence || DEFAULT_VERSION

            parser = PARSERS.fetch(report.major_version)
            parser.new(report).parse(json)
          rescue JSON::ParserError
            raise LicenseScanningParserError, 'JSON parsing failed'
          rescue => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
            raise LicenseScanningParserError, 'License scanning report parsing failed'
          end
        end
      end
    end
  end
end
