require 'spec_helper'

describe 'JIRA authorization requests' do
  let(:user) { create :user }
  let(:application) { create :oauth_application, scopes: 'api' }
  let(:redirect_uri) { oauth_jira_callback_url(host: "http://www.example.com") }

  def generate_access_grant
    create :oauth_access_grant, application: application, resource_owner_id: user.id, redirect_uri: redirect_uri
  end

  describe 'POST access_token' do
    it 'should return values similar to a POST to /oauth/token' do
      post_data = {
        client_id: application.uid,
        client_secret: application.secret
      }

      post '/oauth/token', params: post_data.merge({
        code: generate_access_grant.token,
        grant_type: 'authorization_code',
        redirect_uri: redirect_uri
      })
      oauth_response = json_response

      post '/login/oauth/access_token', params: post_data.merge({
        code: generate_access_grant.token
      })
      jira_response = response.body

      access_token, scope, token_type = oauth_response.values_at('access_token', 'scope', 'token_type')
      expect(jira_response).to eq("access_token=#{access_token}&scope=#{scope}&token_type=#{token_type}")
    end
  end
end
