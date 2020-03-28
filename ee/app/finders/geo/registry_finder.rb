# frozen_string_literal: true

module Geo
  class RegistryFinder
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :current_node_id

    delegate :selective_sync?, to: :current_node, allow_nil: true

    def initialize(current_node_id: nil)
      @current_node_id = current_node_id
    end

    private

    def current_node(fdw: true)
      fdw ? current_node_fdw : current_node_non_fdw
    end

    def current_node_fdw
      strong_memoize(:current_node_fdw) do
        Geo::Fdw::GeoNode.find(current_node_id) if current_node_id
      end
    end

    def current_node_non_fdw
      strong_memoize(:current_node_non_fdw) do
        GeoNode.find(current_node_id) if current_node_id
      end
    end
  end
end
