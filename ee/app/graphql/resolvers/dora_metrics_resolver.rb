# frozen_string_literal: true

module Resolvers
  class DoraMetricsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    authorizes_object!
    authorize :read_dora4_analytics
    type [::Types::DoraMetricType], null: true
    alias_method :container, :object

    argument :metric, Types::DoraMetricTypeEnum,
             required: true,
             description: 'The type of metric to return.'

    argument :start_date, Types::DateType,
             required: false,
             description: 'Date range to start from. Default is 3 months ago.'

    argument :end_date, Types::DateType,
             required: false,
             description: 'Date range to end at. Default is the current date.'

    argument :interval, Types::DoraMetricBucketingIntervalEnum,
             required: false,
             description: 'How the metric should be aggregrated. Defaults to `DAILY`. In the case of `ALL`, the `date` field in the response will be `null`.'

    argument :environment_tier, Types::DeploymentTierEnum,
             required: false,
             description: 'The deployment tier of the environments to return. Defaults to `PRODUCTION`.'

    def resolve(params)
      result = ::Dora::AggregateMetricsService
        .new(container: container, current_user: current_user, params: params)
        .execute

      raise Gitlab::Graphql::Errors::ArgumentError, result[:message] unless result[:status] == :success

      data = result[:data]

      if data.is_a? Numeric
        # When interval=ALL, the service above returns a single number (float or integer)
        # instead of an array of hashes, like it does otherwise.
        # To keep the return value of this resolver consistent, we wrap
        # it in the structure we expect.
        #
        # This can be removed if/when we update the service to always
        # return a consistent shape:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/334821
        [{ 'date' => nil, 'value' => data }]
      else
        data
      end
    end
  end
end
