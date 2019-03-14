# frozen_string_literal: true

module Gitlab
  module Insights
    module Reducers
      class CountPerPeriodReducer < BaseReducer
        InvalidPeriodError = Class.new(BaseReducerError)
        InvalidPeriodFieldError = Class.new(BaseReducerError)

        VALID_PERIOD = %w[day week month].freeze
        VALID_PERIOD_FIELD = %i[created_at].freeze

        def initialize(issuables, period:, period_field: :created_at)
          super(issuables)
          @period = period.to_s.singularize
          @period_field = period_field

          validate!
        end

        # Returns a hash { period => value_for_period(issuables) }, e.g.
        #   {
        #     'January 2019' => 1,
        #     'February 2019' => 1,
        #     'March 2019' => 1
        #   }
        def reduce
          issuables_grouped_by_normalized_period.each_with_object({}) do |(period, issuables), hash|
            hash[period.strftime(period_format)] = value_for_period(issuables)
          end
        end

        private

        attr_reader :period, :period_field

        def validate!
          unless VALID_PERIOD.include?(period)
            raise InvalidPeriodError, "Invalid value for `period`: `#{period}`. Allowed values are #{VALID_PERIOD}!"
          end

          unless VALID_PERIOD_FIELD.include?(period_field)
            raise InvalidPeriodFieldError, "Invalid value for `period_field`: `#{period_field}`. Allowed values are #{VALID_PERIOD_FIELD}!"
          end
        end

        # Returns a hash { period => [array of issuables] }, e.g.
        #   {
        #     #<Tue, 01 Jan 2019 00:00:00 UTC +00:00> => [#<Issue id:1 namespace1/project1#1>],
        #     #<Fri, 01 Feb 2019 00:00:00 UTC +00:00> => [#<Issue id:2 namespace1/project1#2>],
        #     #<Fri, 01 Mar 2019 00:00:00 UTC +00:00> => [#<Issue id:3 namespace1/project1#3>]
        #   }
        def issuables_grouped_by_normalized_period
          issuables.group_by do |issuable|
            issuable.public_send(period_field).public_send(period_normalizer) # rubocop:disable GitlabSecurity/PublicSend
          end
        end

        def period_normalizer
          :"beginning_of_#{period}"
        end

        def period_format
          case period
          when 'day'
            '%d %b %y'
          when 'week'
            '%d %b %y'
          when 'month'
            '%B %Y'
          end
        end

        # Can be overridden by subclasses.
        #
        # Returns the count of issuables.
        def value_for_period(issuables)
          issuables.size
        end
      end
    end
  end
end
