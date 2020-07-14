# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class ConfigLoader
        include ::Gitlab::Utils::StrongMemoize

        MissingReportError = Class.new(StandardError)
        MissingSeriesError = Class.new(StandardError)

        DEFAULT_CONFIG = File.join('ee', 'fixtures', 'report_pages', 'default.yml').freeze

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

        private

        def default_config
          strong_memoize(:default_config) do
            yaml = File.read(Rails.root.join(DEFAULT_CONFIG).to_s)
            ::Gitlab::Config::Loader::Yaml.new(yaml).load!
          rescue Gitlab::Config::Loader::FormatError
            {}
          end
        end
      end
    end
  end
end
