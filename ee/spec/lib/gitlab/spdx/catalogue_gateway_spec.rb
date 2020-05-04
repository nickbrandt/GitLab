# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SPDX::CatalogueGateway do
  include StubRequests

  describe "#fetch" do
    let(:result) { subject.fetch }
    let(:url) { described_class::URL }

    context "when the licenses.json endpoint is healthy" do
      let(:spdx_json) { IO.read(Rails.root.join("spec", "fixtures", "spdx.json")) }
      let(:catalogue_hash) { Gitlab::Json.parse(spdx_json, symbolize_names: true) }

      before do
        stub_full_request(url, method: :get).to_return(status: 200, body: spdx_json)
      end

      it { expect(result.count).to be(catalogue_hash[:licenses].count) }
    end

    context "when the licenses.json endpoint is not reachable" do
      before do
        allow(Gitlab::Metrics).to receive(:add_event)
        stub_full_request(url, method: :get).to_return(status: 404)
        result
      end

      it { expect(result.count).to be_zero }
      it { expect(Gitlab::Metrics).to have_received(:add_event).with(:spdx_fetch_failed, http_status_code: 404) }
    end

    Gitlab::HTTP::HTTP_ERRORS.each do |error|
      context "when an `#{error}` is raised while trying to connect to the endpoint" do
        before do
          allow(Gitlab::Metrics).to receive(:add_event)
          stub_full_request(url, method: :get).and_raise(error)
          result
        end

        it { expect(result.count).to be_zero }
        it { expect(Gitlab::Metrics).to have_received(:add_event).with(:spdx_fetch_failed, anything) }
      end
    end
  end
end
