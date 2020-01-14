# frozen_string_literal: true

require 'spec_helper'

describe ContainerRegistry::EventHandler do
  include ::EE::GeoHelpers

  let(:container_repository) { create(:container_repository) }

  let(:event_target_for_push) do
    { 'mediaType' => 'application/vnd.docker.distribution.manifest.v2+json', 'repository' => container_repository.path }
  end

  let(:event_target_for_delete) do
    { 'tag' => 'latest', 'repository' => container_repository.path }
  end

  let_it_be(:primary_node)   { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  before do
    stub_current_geo_node(primary_node)
  end

  it 'creates event for push' do
    push_event = { action: 'push', target: event_target_for_push }.with_indifferent_access

    expect { described_class.new([push_event]).execute }
        .to change { ::Geo::ContainerRepositoryUpdatedEvent.count }.by(1)
  end

  it 'creates event for delete' do
    delete_event = { action: 'delete', target: event_target_for_delete }.with_indifferent_access

    expect { described_class.new([delete_event]).execute }
        .to change { ::Geo::ContainerRepositoryUpdatedEvent.count }.by(1)
  end

  it 'ignores pull events' do
    pull_event = { action: 'pull', target: {} }.with_indifferent_access

    expect { described_class.new([pull_event]).execute }
        .to change { ::Geo::ContainerRepositoryUpdatedEvent.count }.by(0)
  end
end
