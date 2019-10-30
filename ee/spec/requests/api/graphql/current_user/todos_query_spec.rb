# frozen_string_literal: true

require 'spec_helper'

describe 'getting project information' do
  include GraphqlHelpers

  set(:current_user) { create(:user) }
  set(:design_todo) { create(:todo, user: current_user, target: create(:design)) }
  set(:epic_todo) { create(:todo, user: current_user, target: create(:epic)) }
  let(:fields) do
    <<~QUERY
    nodes {
      #{all_graphql_fields_for('todos'.classify)}
    }
    QUERY
  end
  let(:query) do
    graphql_query_for('currentUser', {}, query_graphql_field('todos', {}, fields))
  end

  subject { graphql_data.dig('currentUser', 'todos', 'nodes') }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns Todos for all target types' do
    is_expected.to include(
      a_hash_including('targetType' => 'DESIGN'),
      a_hash_including('targetType' => 'EPIC')
    )
  end
end
