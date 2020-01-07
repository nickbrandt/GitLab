# frozen_string_literal: true

module Security
  # Service for fetching summary statistics from ElasticSearch.
  # Queries ES and retrieves both total nginx requests & modsec violations
  #
  class WafAnomalySummaryService < ::BaseService
    INGRESS_CONTAINER_NAME = 'nginx-ingress-controller'

    def initialize(environment:, interval: 'day', from: 30.days.ago.iso8601, to: Time.zone.now.iso8601)
      @environment = environment
      @interval = interval
      @from = from
      @to = to
    end

    def execute
      return if elasticsearch_client.nil?

      aggregate_results = elasticsearch_client.msearch(body: body)
      nginx_results, modsec_results = aggregate_results["responses"]

      nginx_total_requests = nginx_results.dig("hits", "total").to_f
      modsec_total_requests = modsec_results.dig("hits", "total").to_f

      anomalous_traffic_count = nginx_total_requests.zero? ? 0 : (modsec_total_requests / nginx_total_requests).round(2)

      {
        total_traffic: nginx_total_requests.round,
        anomalous_traffic: anomalous_traffic_count,
        history: {
          nominal: histogram_from(nginx_results),
          anomalous: histogram_from(modsec_results)
        },
        interval: @interval,
        from: @from,
        to: @to,
        status: :success
      }
    end

    def body
      aggregation = aggregations(@interval)

      [
        { index: indices },
        {
          query: nginx_requests_query,
          aggs: aggregation,
          size: 0 # no docs needed, only counts
        },
        { index: indices },
        {
          query: modsec_requests_query,
          aggs: aggregation,
          size: 0 # no docs needed, only counts
        }
      ]
    end

    def elasticsearch_client
      @client ||= @environment.deployment_platform.cluster.application_elastic_stack&.elasticsearch_client
    end

    private

    # Construct a list of daily indices to be searched. We do this programmatically
    # based on the requested timeframe to reduce the load of querying all previous
    # indices
    def indices
      (@from.to_date..@to.to_date).map do |day|
        "filebeat-*-#{day.strftime('%Y.%m.%d')}"
      end
    end

    def modsec_requests_query
      {
        bool: {
          must: [
            {
              range: {
                "@timestamp" => {
                    gte: @from,
                    lte: @to
                }
              }
            },
            {
              match_phrase: {
                "kubernetes.container.name" => {
                  query: ::Clusters::Applications::Ingress::MODSECURITY_LOG_CONTAINER_NAME
                }
              }
            },
            {
              match_phrase: {
                "kubernetes.namespace" => {
                  query: Gitlab::Kubernetes::Helm::NAMESPACE
                }
              }
            }
          ]
        }
      }
    end

    def nginx_requests_query
      {
        bool: {
          must: [
            {
              range: {
                "@timestamp" => {
                    gte: @from,
                    lte: @to
                }
              }
            },
            {
              "term": {
                "message.upstream": "[#{environment_proxy_upstream_name}]"
              }
            },
            {
              match_phrase: {
                "kubernetes.container.name" => {
                  query: INGRESS_CONTAINER_NAME
                }
              }
            },
            {
              match_phrase: {
                "kubernetes.namespace" => {
                  query: Gitlab::Kubernetes::Helm::NAMESPACE
                }
              }
            },
            {
              match_phrase: {
                "stream" => {
                  query: "stdout"
                }
              }
            }
          ]
        }
      }
    end

    def aggregations(interval)
      {
        counts: {
          date_histogram: {
            field: "@timestamp",
            interval: interval,
            order: {
              "_key": "asc"
            }
          }
        }
      }
    end

    def histogram_from(results)
      buckets = results.dig("aggregations", "counts", "buckets") || []

      buckets.map { |bucket| [bucket["key_as_string"], bucket["doc_count"]] }
    end

    # Derive proxy upstream name to filter nginx log by environment
    # See https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/log-format/
    #
    # This depends on a static service name and port, as defaulted by auto-deploy job
    def environment_proxy_upstream_name
      "#{@environment.deployment_namespace}-#{@environment.slug}-#{@environment.slug}-auto-deploy-5000"
    end
  end
end
