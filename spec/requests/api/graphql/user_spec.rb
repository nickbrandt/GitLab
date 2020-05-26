# frozen_string_literal: true

require 'spec_helper'

describe 'User' do
  include GraphqlHelpers

  context 'when current user' do
    let_it_be(:user) { create(:user) }

    context 'is not an administrator' do
      let_it_be(:current_user) { create(:user) }

      it 'successfully reads the currently logged in user' do
        query = graphql_query_for(:user, { id: current_user.id }, [:id])
        post_graphql(query, current_user: current_user)
        expect(graphql_data.dig('user', 'id')).to eq(current_user.to_global_id.uri.to_s)
      end

      it 'fails to read any other user' do
        query = graphql_query_for(:user, { id: user.id }, [:id])
        post_graphql(query, current_user: current_user)
        expect(graphql_data.dig('user', 'id')).not_to eq(current_user.to_global_id.uri.to_s)
      end
    end

    context 'is an adminstrator' do
      let_it_be(:current_user) { create(:user, :admin) }
      let_it_be(:user) { create(:user) }

      it 'successfully reads any other user' do
        query = graphql_query_for(:user, { id: user.id }, [:id])
        post_graphql(query, current_user: current_user)
        expect(graphql_data.dig('user', 'id')).to eq(user.to_global_id.uri.to_s)
      end
    end
  end
end
