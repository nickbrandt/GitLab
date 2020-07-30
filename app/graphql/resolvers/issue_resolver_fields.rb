# frozen_string_literal: true

module Resolvers
  module IssueResolverFields
    extend ActiveSupport::Concern

    prepended do
      argument :iid, GraphQL::STRING_TYPE,
                required: false,
                description: 'IID of the issue. For example, "1"'

      argument :iids, [GraphQL::STRING_TYPE],
                required: false,
                description: 'List of IIDs of issues. For example, [1, 2]'
      argument :state, Types::IssuableStateEnum,
                required: false,
                description: 'Current state of this issue'
      argument :label_name, GraphQL::STRING_TYPE.to_list_type,
                required: false,
                description: 'Labels applied to this issue'
      argument :milestone_title, GraphQL::STRING_TYPE.to_list_type,
                required: false,
                description: 'Milestones applied to this issue'
      argument :assignee_username, GraphQL::STRING_TYPE,
                required: false,
                description: 'Username of a user assigned to the issues'
      argument :assignee_id, GraphQL::STRING_TYPE,
                required: false,
                description: 'ID of a user assigned to the issues, "none" and "any" values supported'
      argument :created_before, Types::TimeType,
                required: false,
                description: 'Issues created before this date'
      argument :created_after, Types::TimeType,
                required: false,
                description: 'Issues created after this date'
      argument :updated_before, Types::TimeType,
                required: false,
                description: 'Issues updated before this date'
      argument :updated_after, Types::TimeType,
                required: false,
                description: 'Issues updated after this date'
      argument :closed_before, Types::TimeType,
                required: false,
                description: 'Issues closed before this date'
      argument :closed_after, Types::TimeType,
                required: false,
                description: 'Issues closed after this date'
      argument :search, GraphQL::STRING_TYPE,
                required: false,
                description: 'Search query for issue title or description'
      argument :sort, Types::IssueSortEnum,
                description: 'Sort issues by this criteria',
                required: false,
                default_value: 'created_desc'
      argument :types, [Types::IssueTypeEnum],
                as: :issue_types,
                description: 'Filter issues by the given issue types',
                required: false
    end
  end
end
