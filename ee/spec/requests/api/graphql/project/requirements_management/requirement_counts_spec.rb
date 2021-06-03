# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting requirement counts for a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:requirement1) { create(:requirement, project: project, state: :opened) }
  let_it_be(:requirement2) { create(:requirement, :closed, project: project) }

  let(:counts) { graphql_data['project']['requirementStatesCount'] }

  let(:fields) do
    <<~QUERY
    opened
    closed
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('requirementStatesCount', {}, fields)
    )
  end

  shared_examples 'nil requirement counts' do
    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(counts).to be_nil
    end
  end

  context 'when user has access to the project' do
    before do
      stub_licensed_features(requirements: true)
      project.add_developer(current_user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'returns requirement counts' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_nil
      expect(counts['opened']).to eq 1
      expect(counts['closed']).to eq 1
    end

    # remove this in %14.6
    context 'using `archived` as alias for `closed`' do
      let(:fields) do
        <<~QUERY
        opened
        closed
        archived
        QUERY
      end

      it 'returns requirement counts' do
        post_graphql(query, current_user: current_user)

        expect(graphql_errors).to be_nil
        expect(counts['opened']).to eq 1
        expect(counts['closed']).to eq 1
        expect(counts['archived']).to eq 1
      end
    end
  end

  context 'when the user does not have access to the requirement' do
    before do
      stub_licensed_features(requirements: true)
    end

    it 'returns nil' do
      post_graphql(query)

      expect(graphql_data['project']).to be_nil
    end
  end

  context 'when requirements feature is not available' do
    before do
      stub_licensed_features(requirements: false)
      project.add_developer(current_user)
    end

    it_behaves_like 'nil requirement counts'
  end

  context 'when there are no requirements in the project' do
    let(:project) { create(:project) }

    before do
      stub_licensed_features(requirements: true)
      project.add_developer(current_user)
    end

    it 'returns zero values for missing states' do
      post_graphql(query, current_user: current_user)

      expect(graphql_errors).to be_nil
      expect(counts['opened']).to eq 0
      expect(counts['closed']).to eq 0
    end
  end
end
