# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class ConfigLoader
        MissingReportError = Class.new(StandardError)
        MissingSeriesError = Class.new(StandardError)

        DEFAULT_CONFIG = File.join('ee', 'fixtures', 'report_pages', 'default.yml').freeze

        class << self
          def find_report_by_id!(report_id)
            raw_report = default_config[report_id.to_s.to_sym]

            raise(MissingReportError.new) if raw_report.nil?

            ReportBuilder.build(raw_report.merge(id: report_id))
          end

          def find_series_by_id!(report_id, series_id)
            report = find_report_by_id!(report_id)

            series = report.find_series_by_id(series_id)

            raise(MissingSeriesError.new) if series.nil?

            series
          end

          def default_config
            yaml = File.read(Rails.root.join(DEFAULT_CONFIG).to_s)
            ::Gitlab::Config::Loader::Yaml.new(yaml).load!
          rescue Gitlab::Config::Loader::FormatError
            {}
          end
        end

        private_class_method :default_config
      end
    end
  end
end
