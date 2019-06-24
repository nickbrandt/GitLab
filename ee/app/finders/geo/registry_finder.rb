# frozen_string_literal: true

module Geo
  class RegistryFinder
    attr_reader :current_node

    delegate :selective_sync?, to: :current_node, allow_nil: true

    def initialize(current_node: nil)
      @current_node = current_node
    end
  end
end
