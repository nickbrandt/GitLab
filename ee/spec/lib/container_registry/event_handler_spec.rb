# frozen_string_literal: true

require 'spec_helper'

describe ContainerRegistry::EventHandler do
  include ::EE::GeoHelpers

  let(:container_repository) { create(:container_repository) }

  let(:event_target) do
    { 'mediaType' => 'application/vnd.docker.distribution.manifest.v2+json', 'repository' => container_repository.path }
  end

  set(:primary_node)   { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }

  before do
    stub_current_geo_node(primary_node)
  end

  it 'creates event' do
    push_event = { action: 'push', target: event_target }.with_indifferent_access

    expect { described_class.new([push_event]).execute }
        .to change { ::Geo::ContainerRepositoryUpdatedEvent.count }.by(1)
  end

  it 'ignores non-push events' do
    pull_event = { action: 'pull', target: event_target }.with_indifferent_access

    expect { described_class.new([pull_event]).execute }
        .to change { ::Geo::ContainerRepositoryUpdatedEvent.count }.by(0)
  end
end
