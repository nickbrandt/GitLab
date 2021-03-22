# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomersDot::ProxyController do
  describe 'POST graphql' do
    let_it_be(:customers_dot) { "#{Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL}/graphql" }

    it 'forwards request body to customers dot' do
      request_body = '{ "foo" => "bar" }'

      stub_request(:post, customers_dot)

      post :graphql, body: request_body

      expect(WebMock).to have_requested(:post, customers_dot).with(body: request_body)
    end

    it 'responds with customers dot status' do
      stub_request(:post, customers_dot).to_return(status: 500)

      post :graphql

      expect(response).to have_gitlab_http_status(:internal_server_error)
    end

    it 'responds with customers dot response body' do
      customers_dot_response = 'foo'

      stub_request(:post, customers_dot).to_return(body: customers_dot_response)

      post :graphql

      expect(response.body).to eq(customers_dot_response)
    end
  end
end
