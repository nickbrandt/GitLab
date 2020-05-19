# frozen_string_literal: true

module Mutations
  module Discussions
    class Unresolve < Base
      graphql_name 'DiscussionUnresolve'

      def resolve(id:)
        discussion = authorized_find_discussion!(id: id)

        discussion.unresolve!

        {
          discussion: discussion,
          errors: [] # Todo
        }
      end
    end
  end
end
