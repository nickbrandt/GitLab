# frozen_string_literal: true

module Resolvers
  class EpicIssuesResolver < BaseResolver
    type Types::EpicIssueType, null: true

    alias_method :epic, :object

    # When using EpicIssuesResolver then epic's issues are authorized when
    # rendering lazy-loaded issues, we explicitly ignore any inherited
    # type_authorizations to avoid excuting any authorization checks in earlier
    # phase
    def self.skip_authorizations?
      true
    end

    def resolve(**args)
      filter = proc do |issues|
        Ability.issues_readable_by_user(issues, context[:current_user])
      end

      Gitlab::Graphql::Loaders::BatchEpicIssuesLoader.new(epic.id, filter).find
    end
  end
end
