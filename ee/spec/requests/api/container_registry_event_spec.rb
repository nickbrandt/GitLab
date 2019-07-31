# frozen_string_literal: true

require 'spec_helper'

describe API::ContainerRegistryEvent do
  let(:secret_token) { 'secret_token' }
  let(:events) { [{ action: 'push' }] }
  let(:registry_headers) { { 'Content-Type' => ::API::ContainerRegistryEvent::DOCKER_DISTRIBUTION_EVENTS_V1_JSON } }

  describe 'POST /container_registry_event/events' do
    before do
      stub_registry_endpoints_configuration([{
        name: 'geo_event',
        headers: { 'Authorization' => secret_token }
      }.with_indifferent_access])
    end

    it 'returns 200 status and events are passed to event handler' do
      handler = spy(:handle)
      allow(::ContainerRegistry::EventHandler).to receive(:new).with(events).and_return(handler)

      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => secret_token)

      expect(handler).to have_received(:execute).once
      expect(response.status).to eq 200
    end

    it 'returns 401 error status when token is invalid' do
      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => 'invalid_token')

      expect(response.status).to eq 401
    end

    it 'returns 401 error status when feature is disabled' do
      stub_feature_flags(geo_registry_replication: false)

      expect(::ContainerRegistry::EventHandler).not_to receive(:new)

      post api('/container_registry_event/events'),
           params: { events: events }.to_json,
           headers: registry_headers.merge('Authorization' => secret_token)

      expect(response.status).to eq 401
    end

    def stub_registry_endpoints_configuration(configuration)
      allow(Gitlab.config.registry).to receive(:notifications) { configuration }
    end
  end
end
