# frozen_string_literal: true
module Types
  module Repository
    # rubocop: disable Graphql/AuthorizeTypes
    # This is presented through `Repository` that has its own authorization
    class BlobType < BaseObject
      present_using BlobPresenter

      graphql_name 'RepositoryBlob'

      field :id, GraphQL::ID_TYPE, null: false,
            description: 'ID of the blob.'

      field :oid, GraphQL::STRING_TYPE, null: false, method: :id,
            description: 'OID of the blob.'

      field :path, GraphQL::STRING_TYPE, null: false,
            description: 'Path of the blob.'

      field :name, GraphQL::STRING_TYPE,
            description: 'Blob name.',
            null: true

      field :mode, type: GraphQL::STRING_TYPE,
            description: 'Blob mode.',
            null: true

      field :lfs_oid, GraphQL::STRING_TYPE, null: true,
            calls_gitaly: true,
            description: 'LFS OID of the blob.'

      field :web_path, GraphQL::STRING_TYPE, null: true,
            description: 'Web path of the blob.'

      field :size, GraphQL::INT_TYPE, null: true,
            description: 'Size (in bytes) of the blob.'

      field :raw_size, GraphQL::INT_TYPE, null: true,
            description: 'Size (in bytes) of the blob, or the blob target if stored externally.'

      field :raw_blob, GraphQL::STRING_TYPE, null: true, method: :data,
            description: 'The raw content of the blob.'

      field :raw_text_blob, GraphQL::STRING_TYPE, null: true, method: :text_only_data,
            description: 'The raw content of the blob, if the blob is text data.'

      field :stored_externally, GraphQL::BOOLEAN_TYPE, null: true, method: :stored_externally?,
            description: "Whether the blob's content is stored externally (for instance, in LFS)."

      field :edit_blob_path, GraphQL::STRING_TYPE, null: true,
            description: 'Web path to edit the blob in the old-style editor.'

      field :raw_path, GraphQL::STRING_TYPE, null: true,
            description: 'Web path to download the raw blob.'

      field :replace_path, GraphQL::STRING_TYPE, null: true,
            description: 'Web path to replace the blob content.'

      field :file_type, GraphQL::STRING_TYPE, null: true,
            description: 'The expected format of the blob based on the extension.'

      field :simple_viewer, type: Types::BlobViewerType,
            description: 'Blob content simple viewer.',
            null: false

      field :rich_viewer, type: Types::BlobViewerType,
            description: 'Blob content rich viewer.',
            null: true

      def raw_text_blob
        object.data unless object.binary?
      end

      def lfs_oid
        Gitlab::Graphql::Loaders::BatchLfsOidLoader.new(object.repository, object.id).find
      end
    end
  end
end

Types::Repository::BlobType.prepend_if_ee('::EE::Types::Repository::BlobType')
