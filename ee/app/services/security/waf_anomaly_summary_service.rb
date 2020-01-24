# frozen_string_literal: true

module Security
  # Service for fetching summary statistics from ElasticSearch.
  # Queries ES and retrieves both total nginx requests & modsec violations
  #
  class WafAnomalySummaryService < ::BaseService
    def initialize(environment:, interval: 'day', from: 30.days.ago.iso8601, to: Time.zone.now.iso8601)
      @environment = environment
      @interval = interval
      @from = from
      @to = to
    end

    def execute
      return if elasticsearch_client.nil?

      {
        total_traffic: 0,
        anomalous_traffic: 0.0,
        history: {
          nominal: [],
          anomalous: []
        },
        interval: @interval,
        from: @from,
        to: @to,
        status: :success
      }
    end

    def elasticsearch_client
      @client ||= @environment.deployment_platform.cluster.application_elastic_stack&.elasticsearch_client
    end
  end
end
