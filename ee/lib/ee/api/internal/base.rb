# frozen_string_literal: true

module EE
  module API
    module Internal
      module Base
        extend ActiveSupport::Concern

        prepended do
          helpers do
            extend ::Gitlab::Utils::Override

            override :lfs_authentication_url
            def lfs_authentication_url(project)
              project.lfs_http_url_to_repo(params[:operation])
            end

            override :ee_post_receive_response_hook
            def ee_post_receive_response_hook(response)
              response.add_basic_message(geo_secondary_lag_message) if ::Gitlab::Geo.primary?
            end

            def geo_secondary_lag_message
              lag = current_replication_lag
              return if lag.to_i <= 0

              "Current replication lag: #{lag} seconds"
            end

            def current_replication_lag
              fetch_geo_node_referrer&.status&.db_replication_lag_seconds
            end

            def fetch_geo_node_referrer
              ::Gitlab::Geo::GitPushHttp.new(params[:identifier], params[:gl_repository]).fetch_referrer_node
            end

            override :check_allowed
            def check_allowed(params)
              ip = params.fetch(:check_ip, nil)
              ::Gitlab::IpAddressState.with(ip) do # rubocop: disable CodeReuse/ActiveRecord
                super
              end
            end
          end
        end
      end
    end
  end
end
