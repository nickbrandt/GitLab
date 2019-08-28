# frozen_string_literal: true

module EE
  module Gitlab
    module Metrics
      module Dashboard
        module ServiceSelector
          extend ActiveSupport::Concern

          class_methods do
            def call(params)
              return ::Metrics::Dashboard::ClusterDashboardService if params[:cluster]

              super
            end
          end
        end
      end
    end
  end
end
