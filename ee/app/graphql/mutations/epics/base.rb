# frozen_string_literal: true

module Mutations
  module Epics
    class Base < ::Mutations::BaseMutation
      include Mutations::ResolvesGroup

      argument :iid, GraphQL::ID_TYPE,
               required: true,
               description: "The iid of the epic to mutate"

      argument :group_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The group the epic to mutate belongs to'

      field :epic,
            Types::EpicType,
            null: true,
            description: 'The epic after mutation'

      private

      def find_object(group_path:, iid:)
        group = resolve_group(full_path: group_path)
        resolver = Resolvers::EpicResolver
                     .single.new(object: group, context: context, field: nil)

        resolver.resolve(iid: iid)
      end
    end
  end
end
