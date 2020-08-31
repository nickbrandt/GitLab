# frozen_string_literal: true

module EE
  module Types
    module MergeRequestType
      extend ActiveSupport::Concern

      prepended do
        field :approved, GraphQL::BOOLEAN_TYPE, method: :approved?, null: false,
          description: 'Indicates if the merge request has all the required approvals. Returns true if no required approvals are configured.'
        field :approved_by, ::Types::UserType.connection_type, null: true,
              description: 'Users who approved the merge request'

        def approved_by
          object.approver_users
        end
      end
    end
  end
end
