# frozen_string_literal: true

module Types
  class SourceType < BaseUnion
    graphql_name 'Source'
    description 'Represents an object source type'

    possible_types Types::GroupType, Types::ProjectType

    def self.resolve_type(object, context)
      case object.class
      when Project
        Types::ProjectType
      else
        Types::GroupType
      end
    end
  end
end
