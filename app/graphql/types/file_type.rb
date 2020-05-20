# frozen_string_literal: true

module Types
  class FileType < BaseObject
    graphql_name 'File'

    field :content, GraphQL::STRING_TYPE, null: false,
          description: 'Content of the file'
  end
end
