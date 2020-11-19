module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class JobArtifactType < BaseObject
      graphql_name 'CiJobArtifact'

      field :download_path, GraphQL::STRING_TYPE, null: true,
        description: '...'
    end
  end
end
