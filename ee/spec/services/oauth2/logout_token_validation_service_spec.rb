require 'spec_helper'

describe Oauth2::LogoutTokenValidationService do
  let(:user) { create(:user) }
  let(:node) { create(:geo_node) }
  let(:access_token) { create(:doorkeeper_access_token, resource_owner_id: user.id, application_id: node.oauth_application_id) }
  let(:oauth_return_to) { '/project/test' }
  let(:oauth_session) { Gitlab::Geo::OauthSession.new(access_token: access_token.token, return_to: oauth_return_to) }
  let(:logout_state) { oauth_session.generate_logout_state }

  context '#execute' do
    it 'return error when params are empty' do
      result = described_class.new(user, {}).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when state param is nil' do
      result = described_class.new(user, state: nil).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when state param is empty' do
      result = described_class.new(user, state: '').execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when token has incorrect encoding' do
      allow_any_instance_of(Gitlab::Geo::OauthSession)
        .to receive(:extract_logout_token)
        .and_return("\xD800\xD801\xD802")

      result = described_class.new(user, state: logout_state).execute

      expect(result[:status]).to eq(:error)
    end

    it 'returns error when current user is nil' do
      result = described_class.new(nil, state: logout_state).execute

      expect(result).to eq(status: :error, message: 'User could not be found')
    end

    it 'returns error when token owner could not be found' do
      allow(User).to receive(:find).with(user.id).and_return(nil)

      result = described_class.new(user, state: logout_state).execute

      expect(result).to eq(status: :error, message: 'User could not be found')
    end

    it 'returns error when token does not belong to the current user' do
      result = described_class.new(create(:user), state: logout_state).execute

      expect(result).to eq(status: :error, message: 'User could not be found')
    end

    context 'when token is valid' do
      it 'returns success' do
        result = described_class.new(user, state: logout_state).execute

        expect(result).to include(status: :success)
      end

      context 'when OAuth session return_to param is nil' do
        it 'returns the Geo node URL associated with OAuth application to redirect the user back' do
          oauth_session = Gitlab::Geo::OauthSession.new(access_token: access_token.token, return_to: nil)
          logout_state = oauth_session.generate_logout_state

          result = described_class.new(user, state: logout_state).execute

          expect(result).to include(return_to: node.url)
        end
      end

      context 'when OAuth session return_to param is empty' do
        it 'returns the Geo node URL associated with OAuth application to redirect the user back' do
          oauth_session = Gitlab::Geo::OauthSession.new(access_token: access_token.token, return_to: '')
          logout_state = oauth_session.generate_logout_state

          result = described_class.new(user, state: logout_state).execute

          expect(result).to include(return_to: node.url)
        end
      end

      context 'when OAuth session return_to param is set' do
        it 'returns the fullpath to the Geo node to redirect the user back' do
          result = described_class.new(user, state: logout_state).execute

          expect(result).to include(return_to: "#{node.url.chomp('/')}/project/test")
        end

        it 'replaces the host with the Geo node associated with OAuth application' do
          oauth_return_to = 'http://fake-secondary/project/test'
          oauth_session = Gitlab::Geo::OauthSession.new(access_token: access_token.token, return_to: oauth_return_to)
          logout_state = oauth_session.generate_logout_state

          result = described_class.new(user, state: logout_state).execute

          expect(result).to include(return_to: "#{node.url.chomp('/')}/project/test")
        end

        it 'handles leading and trailing slashes correctly on return_to path' do
          oauth_return_to = '//project/test'
          oauth_session = Gitlab::Geo::OauthSession.new(access_token: access_token.token, return_to: oauth_return_to)
          logout_state = oauth_session.generate_logout_state

          result = described_class.new(user, state: logout_state).execute

          expect(result).to include(return_to: "#{node.url.chomp('/')}/project/test")
        end
      end
    end
  end
end
