# frozen_string_literal: true

module EE
  module API
    module Internal
      module Base
        extend ActiveSupport::Concern

        prepended do
          helpers do
            include ::Gitlab::Utils::StrongMemoize
            extend ::Gitlab::Utils::Override

            override :lfs_authentication_url
            def lfs_authentication_url(project)
              project.lfs_http_url_to_repo(params[:operation])
            end

            override :ee_post_receive_response_hook
            def ee_post_receive_response_hook(response)
              response.add_basic_message(geo_redirect_to_primary_message) if display_geo_redirect_to_primary_message?
              response.add_basic_message(geo_secondary_lag_message) if geo_display_secondary_lag_message?
            end

            def geo_display_secondary_lag_message?
              ::Gitlab::Geo.primary? && geo_current_replication_lag.to_i > 0
            end

            def geo_secondary_lag_message
              "Current replication lag: #{geo_current_replication_lag} seconds"
            end

            def geo_current_replication_lag
              strong_memoize(:geo_current_replication_lag) do
                geo_referred_node&.status&.db_replication_lag_seconds
              end
            end

            def geo_referred_node
              strong_memoize(:geo_referred_node) do
                ::Gitlab::Geo::GitPushHttp.new(params[:identifier], params[:gl_repository]).fetch_referrer_node
              end
            end

            def display_geo_redirect_to_primary_message?
              ::Gitlab::Geo.primary? && geo_redirect_to_primary_message
            end

            def geo_redirect_to_primary_message
              return unless geo_referred_node

              @geo_redirect_to_primary_message ||= begin
                url = "#{::Gitlab::Geo.current_node.url.chomp('/')}/#{project.full_path}.git"
                ::Gitlab::Geo.redirecting_push_to_primary_message(url)
              end
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
