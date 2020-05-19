# frozen_string_literal: true

module Mutations
  module Discussions
    class Resolve < Base
      graphql_name 'DiscussionResolve'

      def resolve(id:)
        discussion = authorized_find_discussion!(id: id)

        ::Discussions::ResolveService.new(discussion.project, current_user).execute(discussion)

        {
          discussion: discussion,
          errors: [] # TODO look into whether we could receive errors from the service
        }
      end
    end
  end
end
