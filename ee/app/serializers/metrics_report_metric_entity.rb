# frozen_string_literal: true

class MetricsReportMetricEntity < Grape::Entity
  expose :name
  expose :value
end
