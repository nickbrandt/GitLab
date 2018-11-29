# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::Oauth::Session do
  include EE::GeoHelpers

  let!(:primary_node) { create(:geo_node, :primary) }
  let(:secondary_node) { create(:geo_node) }
  let(:oauth_application) { secondary_node.oauth_application }
  let(:access_token) { create(:doorkeeper_access_token, application: oauth_application) }

  before do
    stub_current_geo_node(secondary_node)
  end

  describe '#authorized_url' do
    it 'returns a valid url to the primary node' do
      expect(subject.authorize_url).to start_with(primary_node.url)
    end
  end

  describe '#authenticate' do
    let(:api_url) { "#{primary_node.url.chomp('/')}/api/v4/user" }
    let(:user_json) { ActiveSupport::JSON.encode({ id: 555, email: 'user@example.com' }.as_json) }

    context 'on success' do
      before do
        stub_request(:get, api_url).to_return(
          body: user_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'returns hashed user data' do
        parsed_json = JSON.parse(user_json)

        expect(subject.authenticate(access_token.token)).to eq(parsed_json)
      end
    end

    context 'on invalid token' do
      before do
        stub_request(:get, api_url).to_return(status: [401, 'Unauthorized'])
      end

      it 'raises exception' do
        expect { subject.authenticate(access_token.token) }.to raise_error(OAuth2::Error)
      end
    end
  end
end
