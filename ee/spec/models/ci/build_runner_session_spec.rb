# frozen_string_literal: true

require 'spec_helper'

describe Ci::BuildRunnerSession, model: true do
  let!(:build) { create(:ci_build, :with_runner_session) }

  subject { build.runner_session }

  describe '#service_specification' do
    let(:service) { 'foo'}
    let(:port) { 80 }
    let(:path) { 'path' }
    let(:subprotocols) { nil }
    let(:specification) { subject.service_specification(service: service, port: port, path: path, subprotocols: subprotocols) }

    it 'returns service proxy url' do
      expect(specification[:url]).to eq "https://localhost/proxy/#{service}/#{port}/#{path}"
    end

    it 'returns default service proxy websocket subprotocol' do
      expect(specification[:subprotocols]).to eq %w[terminal.gitlab.com]
    end

    it 'returns empty hash if no url' do
      subject.url = ''

      expect(specification).to be_empty
    end

    context 'when port is not present' do
      let(:port) { nil }

      it 'uses the default port name' do
        expect(specification[:url]).to eq "https://localhost/proxy/#{service}/default_port/#{path}"
      end
    end

    context 'when the service is not present' do
      let(:service) { '' }

      it 'uses the service name "build" as default' do
        expect(specification[:url]).to eq "https://localhost/proxy/build/#{port}/#{path}"
      end
    end

    context 'when url is present' do
      it 'returns ca_pem nil if empty certificate' do
        subject.certificate = ''

        expect(specification[:ca_pem]).to be_nil
      end

      it 'adds Authorization header if authorization is present' do
        subject.authorization = 'foobar'

        expect(specification[:headers]).to include(Authorization: ['foobar'])
      end
    end

    context 'when subprotocol is present' do
      let(:subprotocols) { 'foobar' }

      it 'returns the new subprotocol' do
        expect(specification[:subprotocols]).to eq [subprotocols]
      end
    end
  end
end
