# frozen_string_literal: true

module EE
  module Banzai
    module Filter
      module InlineMetricsRedactorFilter
        extend ::Gitlab::Utils::Override

        ROUTE = ::Banzai::Filter::InlineMetricsRedactorFilter::Route

        override :permissions_by_route
        def permissions_by_route
          super.concat([
            ROUTE.new(::Gitlab::Metrics::Dashboard::Url.alert_regex, :read_prometheus_alerts),
            ROUTE.new(::Gitlab::Metrics::Dashboard::Url.clusters_regex, :read_cluster)
          ])
        end
      end
    end
  end
end
