# frozen_string_literal: true

module EE
  module Types
    module NamespaceType
      extend ActiveSupport::Concern

      prepended do
        field :storage_size_limit,
              GraphQL::FLOAT_TYPE,
              null: true,
              description: 'Total storage limit of the root namespace in bytes',
              resolve: -> (obj, _args, _ctx) { EE::Namespace::RootStorageSize.new(obj).limit }

        field :temporary_storage_increase_ends_on,
              ::Types::TimeType,
              null: true,
              description: 'Date until the temporary storage increase is active'
      end
    end
  end
end
