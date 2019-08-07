# frozen_string_literal: true

module RuboCop
  module GraphqlHelpers
    TYPES_DIR = 'app/graphql/types'

    def in_type?(node)
      path = node.location.expression.source_buffer.name

      path.include?(TYPES_DIR)
    end
  end
end
