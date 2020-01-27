# frozen_string_literal: true

module Types
  module ErrorTracking
    # rubocop: disable Graphql/AuthorizeTypes
    class SentryErrorStackTraceType < ::Types::BaseObject
      graphql_name 'SentryErrorStackTrace'
      description 'An object containing a stack trace entry for a Sentry error.'

      field :issue_id, GraphQL::STRING_TYPE,
            null: false,
            description: 'ID of the Sentry error'
      field :date_received, GraphQL::STRING_TYPE,
            null: false,
            description: 'Time the stack trace was received by Sentry'
      field :stack_trace_entries, [Types::ErrorTracking::SentryErrorStackTraceEntryType],
            null: false,
            description: 'Stack trace entries for the Sentry error'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
