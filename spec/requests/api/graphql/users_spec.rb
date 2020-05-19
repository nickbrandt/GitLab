# frozen_string_literal: true

require 'spec_helper'

describe 'Users' do
  include GraphqlHelpers

  context 'when current user' do
    let_it_be(:user) { create(:user) }
    let_it_be(:query) { graphql_query_for(:users, nil, 'nodes { id }') }

    context 'is not an administrator' do
      let_it_be(:current_user) { create(:user) }

      before do
        post_graphql(query, current_user: current_user)
      end

      it 'returns a single record' do
        expect(graphql_data.dig('users', 'nodes').size).to eq(1)
      end

      it 'returns the current_user' do
        expect(graphql_data.dig('users', 'nodes', 0, 'id')).to eq(current_user.to_global_id.uri.to_s)
      end

      it 'fails to read any other user' do
        ids = graphql_data.dig('users', 'nodes').map { |n| n['id'] }
        expect(ids).not_to include(user.to_global_id.uri.to_s)
      end
    end

    context 'is an adminstrator' do
      let_it_be(:current_user) { create(:user, :admin) }
      let_it_be(:user) { create(:user) }

      it 'successfully reads all users' do
        post_graphql(query, current_user: current_user)
        expect(graphql_data.dig('users', 'nodes').size).to eq(User.count)
      end
    end
  end
end
