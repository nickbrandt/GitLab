# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying an Iteration' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:iteration) { create(:iteration, group: group) }

  let(:query) do
    graphql_query_for('iteration', { id: iteration.to_global_id.to_s }, 'title')
  end

  subject { graphql_data['iteration'] }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user has access to the iteration' do
    before_all do
      group.add_guest(current_user)
    end

    it_behaves_like 'a working graphql query'

    it { is_expected.to include('title' => iteration.name) }
  end

  context 'when the user does not have access to the iteration' do
    it_behaves_like 'a working graphql query'

    it { is_expected.to be_nil }
  end

  context 'when ID argument is missing' do
    let(:query) do
      graphql_query_for('iteration', {}, 'title')
    end

    it 'raises an exception' do
      expect(graphql_errors).to include(a_hash_including('message' => "Field 'iteration' is missing required arguments: id"))
    end
  end
end
