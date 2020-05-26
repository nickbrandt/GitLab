# frozen_string_literal: true

module Resolvers
  class UserResolver < BaseResolver
    description 'Retrieve a single user'

    argument :id, GraphQL::ID_TYPE,
             required: true,
             description: 'The ID of a User'

    def resolve(**args)
      ::UserFinder.new(args[:id]).find_by_id
    end
  end
end
