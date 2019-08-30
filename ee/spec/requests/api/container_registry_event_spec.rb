# frozen_string_literal: true

require 'spec_helper'

describe API::ContainerRegistryEvent do
  let(:secret_token) { 'secret_token' }
  let(:events) { [{ action: 'push' }] }
  let(:registry_headers) { { 'Content-Type' => ::API::ContainerRegistryEvent::DOCKER_DISTRIBUTION_EVENTS_V1_JSON } }

  describe 'POST /container_registry_event/events' do
    before do
      allow(Gitlab.config.registry).to receive(:notification_secret) { secret_token }
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
  end
end
