# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class MergeRequestDiffRegistryType < BaseObject
      include ::Types::Geo::RegistryType

      graphql_name 'MergeRequestDiffRegistry'
      description 'Represents the Geo sync and verification state of a merge request diff'

      field :merge_request_diff_id, GraphQL::ID_TYPE, null: false, description: 'ID of the merge request diff.'
    end
  end
end
