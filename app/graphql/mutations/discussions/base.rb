# frozen_string_literal: true

module Mutations
  module Discussions
    class Base < BaseMutation
      argument :id,
               GraphQL::ID_TYPE,
               required: true,
               description: 'The global id of the discussion'

      field :discussion,
            Types::Notes::DiscussionType,
            null: true,
            description: 'The discussion after mutation'

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Discussion)
      end

      # TODO comment about why we need this, rather than the normal authorize
      def authorized_find_discussion!(id:)
        find_object(id: id).tap do |discussion|
          raise_resource_not_available_error! unless discussion.can_resolve?(current_user)
        end
      end
    end
  end
end
