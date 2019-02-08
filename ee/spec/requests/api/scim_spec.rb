# frozen_string_literal: true

require 'spec_helper'

describe API::Scim do
  let(:user) { create(:user) }
  let(:identity) { create(:group_saml_identity, user: user) }
  let(:group) { identity.saml_provider.group }
  let(:token) { create(:personal_access_token, user: user) }

  before do
    stub_licensed_features(group_saml: true)

    group.add_owner(user)
  end

  describe 'GET api/scim/v2/groups/:group/Users' do
    it 'responds with a 200' do
      get api("scim/v2/groups/#{group.full_path}/Users", user, oauth_access_token: token, version: '')

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
