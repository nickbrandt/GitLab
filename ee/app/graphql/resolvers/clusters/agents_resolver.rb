# frozen_string_literal: true

module Resolvers
  module Clusters
    class AgentsResolver < BaseResolver
      type Types::Clusters::AgentType, null: true

      alias_method :project, :object

      def resolve(**args)
        ::Clusters::AgentsFinder
          .new(project, context[:current_user])
          .execute
      end
    end
  end
end
