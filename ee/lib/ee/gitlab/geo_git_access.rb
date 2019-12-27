# frozen_string_literal: true

module EE
  module Gitlab
    module GeoGitAccess
      include ::Gitlab::ConfigHelper
      include ::EE::GitlabRoutingHelper # rubocop: disable Cop/InjectEnterpriseEditionModule
      include GrapePathHelpers::NamedRouteMatcher
      extend ::Gitlab::Utils::Override

      GEO_SERVER_DOCS_URL = 'https://docs.gitlab.com/ee/administration/geo/replication/using_a_geo_server.html'.freeze

      protected

      def project_or_wiki
        project
      end

      private

      def custom_action_for?(cmd)
        return unless receive_pack?(cmd) # git push
        return unless ::Gitlab::Database.read_only?

        ::Gitlab::Geo.secondary_with_primary?
      end

      def custom_action_for(cmd)
        return unless custom_action_for?(cmd)

        payload = {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'api_endpoints' => custom_action_api_endpoints,
            'primary_repo' => primary_http_repo_url
          }
        }

        ::Gitlab::GitAccessResult::CustomAction.new(payload, messages)
      end

      def messages
        messages = proxying_to_primary_message
        lag_message = current_replication_lag_message

        return messages unless lag_message

        messages + ['', lag_message]
      end

      def push_to_read_only_message
        message = super

        if ::Gitlab::Geo.secondary_with_primary?
          message = "#{message}\nPlease use the primary node URL instead: #{geo_primary_url_to_repo}.\nFor more information: #{GEO_SERVER_DOCS_URL}"
        end

        message
      end

      def geo_primary_url_to_repo
        case protocol
        when 'ssh'
          geo_primary_ssh_url_to_repo(project_or_wiki)
        else
          geo_primary_http_url_to_repo(project_or_wiki)
        end
      end

      def primary_http_repo_url
        geo_primary_http_url_to_repo(project_or_wiki)
      end

      def primary_ssh_url_to_repo
        geo_primary_ssh_url_to_repo(project_or_wiki)
      end

      def proxying_to_primary_message
        # This is formatted like this to fit into the console 'box', e.g.
        #
        # remote:
        # remote: You're pushing to a Geo secondary! We'll help you by proxying this
        # remote: request to the primary:
        # remote:
        # remote:   ssh://<user>@<host>:<port>/<group>/<repo>.git
        # remote:
        <<~STR.split("\n")
          You're pushing to a Geo secondary! We'll help you by proxying this
          request to the primary:

            #{primary_ssh_url_to_repo}
        STR
      end

      def current_replication_lag_message
        return if ::Gitlab::Database.read_write? || current_replication_lag.zero?

        "Current replication lag: #{current_replication_lag} seconds"
      end

      def current_replication_lag
        @current_replication_lag ||= ::Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds
      end

      def custom_action_api_endpoints
        [
          api_v4_geo_proxy_git_push_ssh_info_refs_path,
          api_v4_geo_proxy_git_push_ssh_push_path
        ]
      end
    end
  end
end
