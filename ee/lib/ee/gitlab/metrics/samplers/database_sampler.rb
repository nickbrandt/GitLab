# frozen_string_literal: true

module EE
  module Gitlab
    module Metrics
      module Samplers
        module DatabaseSampler
          private

          def host_stats
            super
              .concat(geo_connection_stats)
              .concat(load_balancing_connection_stats)
          end

          def geo_connection_stats
            return [] unless Geo::TrackingBase.connected?

            [{ labels: labels_for_class(Geo::TrackingBase), stats: Geo::TrackingBase.connection_pool.stat }]
          end

          def load_balancing_connection_stats
            return [] unless ::Gitlab::Database::LoadBalancing.enable?

            ActiveRecord::Base.connection.load_balancer.host_list.hosts.map do |host|
              {
                labels: { host: host.host, port: host.port, class: 'Gitlab::Database::LoadBalancing::Host' },
                stats: host.pool.stat
              }
            end
          end
        end
      end
    end
  end
end
