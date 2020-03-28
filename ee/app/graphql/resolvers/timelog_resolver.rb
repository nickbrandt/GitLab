# frozen_string_literal: true

module Resolvers
  class TimelogResolver < BaseResolver
    argument :start_date, Types::TimeType,
              required: true,
              description: 'List time logs within a time range where the logged date is after start_date parameter.'

    argument :end_date, Types::TimeType,
              required: true,
              description: 'List time logs within a time range where the logged date is before end_date parameter.'

    def resolve(**args)
      validate_date_params!(args)
      authorize_group_timelogs!

      find_timelogs(args)
    end

    private

    def find_timelogs(args)
      group.timelogs(args[:start_date], args[:end_date])
    end

    def validate_date_params!(args)
      validate_dates_present!(args[:start_date], args[:end_date])
      validate_dates_difference!(args[:start_date], args[:end_date])
      validate_date_range!(args[:start_date], args[:end_date])
    end

    def valid_object?
      group.present? &&
        group&.feature_available?(:group_timelogs) &&
        group&.user_can_access_group_timelogs?(context[:current_user])
    end

    def authorize_group_timelogs!
      unless valid_object?
        raise Gitlab::Graphql::Errors::ResourceNotAvailable,
          "The resource is not available or you don't have permission to perform this action"
      end
    end

    def validate_dates_present!(start_date, end_date)
      return if start_date.present? && end_date.present?

      raise_argument_error('Both start_date and end_date must be present.')
    end

    def validate_dates_difference!(start_date, end_date)
      return if end_date > start_date

      raise_argument_error('start_date must be earlier than end_date.')
    end

    def validate_date_range!(start_date, end_date)
      return if end_date - start_date <= 60.days

      raise_argument_error('The date range period cannot contain more than 60 days')
    end

    def raise_argument_error(message)
      raise Gitlab::Graphql::Errors::ArgumentError, message
    end

    def group
      @group ||= object.respond_to?(:sync) ? object.sync : object
    end
  end
end
