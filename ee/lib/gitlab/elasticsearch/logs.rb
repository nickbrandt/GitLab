# frozen_string_literal: true

module Gitlab
  module Elasticsearch
    class Logs
      # How many log lines to fetch in a query
      LOGS_LIMIT = 500

      def initialize(client)
        @client = client
      end

      def pod_logs(namespace, pod_name, container_name = nil)
        query = {
          bool: {
            must: [
              {
                match_phrase: {
                  "kubernetes.pod.name" => {
                    query: pod_name
                  }
                }
              },
              {
                match_phrase: {
                  "kubernetes.namespace" => {
                    query: namespace
                  }
                }
              }
            ]
          }
        }

        # A pod can contain multiple containers.
        # By default we return logs from every container
        unless container_name.nil?
          query[:bool][:must] << {
            match_phrase: {
              "kubernetes.container.name" => {
                query: container_name
              }
            }
          }
        end

        body = {
          query: query,
          # reverse order so we can query N-most recent records
          sort: [
            { "@timestamp": { order: :desc } },
            { "offset": { order: :desc } }
          ],
          # only return these fields in the response
          _source: ["@timestamp", "message"],
          # fixed limit for now, we should support paginated queries
          size: ::Gitlab::Elasticsearch::Logs::LOGS_LIMIT
        }

        response = @client.search body: body
        result = response.fetch("hits", {}).fetch("hits", []).map do |hit|
          {
            timestamp: hit["_source"]["@timestamp"],
            message: hit["_source"]["message"]
          }
        end

        # we queried for the N-most recent records but we want them ordered oldest to newest
        result.reverse
      end
    end
  end
end
