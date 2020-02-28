# frozen_string_literal: true

module EE
  module GeoHelpers
    # Actually sets the specified node to be the current one, so it works on new
    # instances of GeoNode, unlike stub_current_geo_node. But this is slower.
    def set_current_geo_node!(node)
      node.name = GeoNode.current_node_name
      node.save!(validate: false)
    end

    def stub_current_geo_node(node)
      allow(::Gitlab::Geo).to receive(:current_node).and_return(node)
      allow(node).to receive(:current?).and_return(true) unless node.nil?
    end

    def stub_primary_node
      allow(::Gitlab::Geo).to receive(:primary?).and_return(true)
      allow(::Gitlab::Geo).to receive(:secondary?).and_return(false)
    end

    def stub_secondary_node
      allow(::Gitlab::Geo).to receive(:primary?).and_return(false)
      allow(::Gitlab::Geo).to receive(:secondary?).and_return(true)
    end

    def stub_node_disabled(node)
      allow(node).to receive(:enabled?).and_return(false)
    end

    def stub_selective_sync(node, value)
      allow(node).to receive(:selective_sync?).and_return(value)
    end

    def stub_healthy_shards(shards)
      ::Gitlab::ShardHealthCache.update(Array(shards))
    end

    def with_no_geo_database_configured(&block)
      allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_return(false)

      yield

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(::Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end
  end
end
