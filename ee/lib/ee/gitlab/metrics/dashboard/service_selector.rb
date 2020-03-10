# frozen_string_literal: true

module EE
  module Gitlab
    module Metrics
      module Dashboard
        module ServiceSelector
          extend ActiveSupport::Concern

          EE_SERVICES = [
            ::Metrics::Dashboard::ClusterMetricsEmbedService,
            ::Metrics::Dashboard::ClusterDashboardService,
            ::Metrics::Dashboard::GitlabAlertEmbedService
          ].freeze

          class_methods do
            extend ::Gitlab::Utils::Override

            private

            override :services
            def services
              EE_SERVICES + super
            end
          end
        end
      end
    end
  end
end
