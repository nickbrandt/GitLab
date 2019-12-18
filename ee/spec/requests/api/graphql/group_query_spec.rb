# frozen_string_literal: true

require 'spec_helper'

describe 'getting group information' do
  include GraphqlHelpers

  let(:user) { create(:user) }

  describe "Query group(fullPath)" do
    def group_query(group)
      graphql_query_for('group', 'fullPath' => group.full_path)
    end

    context 'when Group SSO is enforced' do
      let(:group) { create(:group, :private) }

      before do
        stub_feature_flags(enforced_sso_requires_session: true)
        saml_provider = create(:saml_provider, enforced_sso: true, group: group)
        create(:group_saml_identity, saml_provider: saml_provider, user: user)
        group.add_guest(user)
      end

      it 'returns null data when not authorized' do
        post_graphql(group_query(group))

        expect(graphql_data['group']).to be_nil
      end

      it 'allows access via session' do
        post_graphql(group_query(group), current_user: user)

        expect(response).to have_gitlab_http_status(200)
        expect(graphql_data['group']['id']).to eq(group.to_global_id.to_s)
      end

      it 'allows access via bearer token' do
        token = create(:personal_access_token, user: user).token
        post_graphql(group_query(group), headers: { 'Authorization' => "Bearer #{token}" })

        expect(response).to have_gitlab_http_status(200)
        expect(graphql_data['group']['id']).to eq(group.to_global_id.to_s)
      end
    end
  end
end
