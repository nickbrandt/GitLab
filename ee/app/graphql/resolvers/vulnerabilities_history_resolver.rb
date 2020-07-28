# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesHistoryResolver < VulnerabilitiesBaseResolver
    include Gitlab::Utils::StrongMemoize

    type Types::VulnerabilitiesCountByDayAndSeverityType, null: true

    argument :start_date, GraphQL::Types::ISO8601Date, required: true,
              description: 'First day for which to fetch vulnerability history'

    argument :end_date, GraphQL::Types::ISO8601Date, required: true,
              description: 'Last day for which to fetch vulnerability history'

    def resolve(**args)
      return [] unless vulnerable

      ::Vulnerabilities::HistoricalStatistic
        .between_dates(args[:start_date], args[:end_date])
        .for_project(vulnerable.projects)
        .with_severities_as_separate_rows
        .grouped_by_date
        .to_a
    end
  end
end
