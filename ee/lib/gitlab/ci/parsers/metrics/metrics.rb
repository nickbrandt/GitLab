# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Metrics
        class Metrics
          MetricsParserError = Class.new(::Gitlab::Ci::Parsers::ParserError)

          def parse!(string_data, metrics_report)
            string_data.each_line { |line| metrics_report.add_metric(*line.split) }
          rescue => e
            Gitlab::Sentry.track_exception(e)
            raise MetricsParserError, "Metrics parsing failed"
          end
        end
      end
    end
  end
end
