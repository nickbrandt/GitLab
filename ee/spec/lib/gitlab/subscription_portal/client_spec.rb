# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SubscriptionPortal::Client do
  describe '#create_trial_account' do
    let(:http_response) { nil }
    let(:httparty_response) do
      double(code: http_response.code, response: http_response, body: {}, parsed_response: {})
    end

    subject do
      described_class.new.generate_trial({})
    end

    context 'when response is successful' do
      let(:http_response) { Net::HTTPSuccess.new(1.0, '201', 'OK') }

      it 'has a successful status' do
        allow(Gitlab::HTTP).to receive(:post).and_return(httparty_response)

        expect(subject[:success]).to eq(true)
      end
    end

    context 'when response code is 422' do
      let(:http_response) { Net::HTTPUnprocessableEntity.new(1.0, '422', 'Error') }

      it 'has a unprocessable entity status' do
        allow(Gitlab::HTTP).to receive(:post).and_return(httparty_response)

        expect(subject[:success]).to eq(false)
      end
    end

    context 'when response code is 500' do
      let(:http_response) { Net::HTTPServerError.new(1.0, '500', 'Error') }

      it 'has a server error status' do
        allow(Gitlab::HTTP).to receive(:post).and_return(httparty_response)

        expect(subject[:success]).to eq(false)
      end
    end
  end
end
