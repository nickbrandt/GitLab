# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class DependencyInput < BaseInputObject
    argument :package, type: Types::PackageInput, required: false,
 description: ""
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
