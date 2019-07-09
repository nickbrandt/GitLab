# frozen_string_literal: true

module EE
  module Gitlab
    module DatabaseImporters
      module CommonMetrics
        module PrometheusMetricEnums
          extend ActiveSupport::Concern

          class_methods do
            extend ::Gitlab::Utils::Override

            override :groups
            def groups
              super.merge(
                # Start at 100 to avoid collisions with CE values
                cluster_health: -100
              )
            end

            override :group_titles
            def group_titles
              super.merge(
                # keys can collide with CE values! please ensure you are not redefining a key that already exists
                cluster_health: _('Cluster Health')
              )
            end
          end
        end
      end
    end
  end
end
