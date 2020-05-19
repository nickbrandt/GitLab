# frozen_string_literal: true

require 'spec_helper'

describe 'Member' do
  include GraphqlHelpers

  context 'when current user' do
    let_it_be(:current_user) { create(:user) }

    context 'requests all memberships' do
      let_it_be(:query) { graphql_query_for(:user, { id: current_user.id }, 'memberships { nodes { createdAt } }') }
      let_it_be(:group_member) { create(:group_member, user: current_user) }
      let_it_be(:project_member) { create(:project_member, user: current_user) }

      context 'belonging to themselves' do
        before do
          post_graphql(query, current_user: current_user)
        end

        it_behaves_like 'a working graphql query'

        it 'returns all memberships' do
          expect(graphql_data.dig('user', 'memberships', 'nodes').size).to eq(2)
        end
      end

      context 'belonging to someone else' do
        let_it_be(:query) { graphql_query_for(:user, { id: create(:user).id }, 'memberships { nodes { createdAt } }') }

        before do
          post_graphql(query, current_user: current_user)
        end

        it_behaves_like 'a working graphql query'

        it 'returns no memberships' do
          expect(graphql_data['user']).to be_nil
        end
      end
    end
  end

  context 'when an administrator' do
    let_it_be(:current_user) { create(:user, :admin) }
    let_it_be(:user) { create(:user) }

    context 'requests all memberships for all users' do
      let_it_be(:query) { graphql_query_for(:users, nil, 'nodes { memberships { nodes { createdAt } } }') }

      let_it_be(:group_member) { create(:group_member, user: user) }
      let_it_be(:project_member) { create(:project_member, user: user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns all memberships including other users' do
        expect(graphql_data.dig('users', 'nodes').size).to eq(User.count)
      end
    end
  end
end
