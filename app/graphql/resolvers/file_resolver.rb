# frozen_string_literal: true

module Resolvers
  class FileResolver < BaseResolver
    prepend FullPathResolver

    type Types::FileType, null: true

    argument :file_path, GraphQL::STRING_TYPE,
              required: true,
              description: 'The ID of an author'

    argument :ref, GraphQL::STRING_TYPE,
              required: true,
              description: 'The ID of an author'

    def resolve(full_path:, file_path:, ref:)
      project_resolver = Resolvers::ProjectResolver.new(object: nil, context: context, field: nil)
      project = project_resolver.resolve(full_path: full_path).sync

      commit = project.commit(ref)
      repo = project.repository

      blob = repo.blob_at(commit.sha, file_path)
      blob.load_all_data!

      { content: blob.data }
    end
  end
end
