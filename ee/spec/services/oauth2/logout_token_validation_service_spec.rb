require 'spec_helper'

describe Oauth2::LogoutTokenValidationService do
  let(:user) { create(:user) }
  let(:node) { create(:geo_node) }
  let(:access_token) { create(:doorkeeper_access_token, resource_owner_id: user.id, application_id: node.oauth_application_id) }
  let(:oauth_session) { Gitlab::Geo::OauthSession.new(access_token: access_token.token) }
  let(:logout_state) { oauth_session.generate_logout_state }

  context '#execute' do
    it 'return error when params are empty' do
      result = described_class.new(user, {}).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when state param is nil' do
      result = described_class.new(user, { state: nil }).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when state param is empty' do
      result = described_class.new(user, { state: '' }).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when incorrect encoding' do
      invalid_token = "\xD800\xD801\xD802"
      allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:extract_logout_token) { invalid_token }

      result = described_class.new(user, { state: logout_state }).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns success when token is valid' do
      result = described_class.new(user, { state: logout_state }).execute

      expect(result).to eq(status: :success, return_to: node.url)
    end
  end
end
