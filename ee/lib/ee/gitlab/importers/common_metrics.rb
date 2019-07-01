# frozen_string_literal: true

module EE
  module Gitlab
    module Importers
      module CommonMetrics
        # rubocop: disable Cop/InjectEnterpriseEditionModule
        def self.prepended(base)
          ::Gitlab::Importers::CommonMetrics::PrometheusMetricEnums.prepend EE::Gitlab::Importers::CommonMetrics::PrometheusMetricEnums
        end
      end
    end
  end
end
