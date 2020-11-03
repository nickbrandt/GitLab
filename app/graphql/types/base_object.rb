# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    prepend Gitlab::Graphql::Present
    prepend Gitlab::Graphql::ExposePermissions
    prepend Gitlab::Graphql::MarkdownField

    field_class Types::BaseField

    def self.accepts(*types)
      @accepts ||= []
      @accepts += types
      @accepts
    end

    # All graphql fields exposing an id, should expose a global id.
    def id
      GitlabSchema.id_from_object(object)
    end

    def current_user
      context[:current_user]
    end

    def self.resolve_type(object, context)
      assignable = accepts

      return self if assignable.blank?

      self if assignable.any? { |cls| object.is_a?(cls) }
    end
  end
end
