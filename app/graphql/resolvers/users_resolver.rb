# frozen_string_literal: true

module Resolvers
  class UsersResolver < BaseResolver
    description 'Retrieve all users'

    def resolve(**args)
      User.all
    end
  end
end
