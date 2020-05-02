# frozen_string_literal: true

require 'spec_helper'

describe 'getting merge request listings nested in a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:label) { create(:label) }
  let_it_be(:merge_request_a) { create(:labeled_merge_request, :unique_branches, source_project: project, labels: [label]) }
  let_it_be(:merge_request_b) { create(:merge_request, :closed, :unique_branches, source_project: project) }
  let_it_be(:merge_request_c) { create(:labeled_merge_request, :closed, :unique_branches, source_project: project, labels: [label]) }
  let_it_be(:merge_request_d) { create(:merge_request, :locked, :unique_branches, source_project: project) }

  let(:results) { graphql_data.dig('project', 'mergeRequests', 'nodes') }

  let(:search_params) { nil }

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('mergeRequests', search_params, [
        query_graphql_field('nodes', nil, all_graphql_fields_for('MergeRequest', max_depth: 1))
      ])
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  shared_examples 'searching with parameters' do
    let(:expected) do
      mrs.map { |mr| a_hash_including('iid' => mr.iid.to_s, 'title' => mr.title) }
    end

    it 'finds the right mrs' do
      post_graphql(query, current_user: current_user)

      expect(results).to match_array(expected)
    end
  end

  context 'there are no search params' do
    let(:search_params) { nil }
    let(:mrs) { [merge_request_a, merge_request_b, merge_request_c, merge_request_d] }

    it_behaves_like 'searching with parameters'
  end

  context 'the search params do not match anything' do
    let(:search_params) { { iids: %w(foo bar baz) } }
    let(:mrs) { [] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by iids' do
    let(:search_params) { { iids: mrs.map(&:iid).map(&:to_s) } }
    let(:mrs) { [merge_request_a, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by state' do
    let(:search_params) { { state: :closed } }
    let(:mrs) { [merge_request_b, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by source_branch' do
    let(:search_params) { { source_branches: mrs.map(&:source_branch) } }
    let(:mrs) { [merge_request_b, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by target_branch' do
    let(:search_params) { { target_branches: mrs.map(&:target_branch) } }
    let(:mrs) { [merge_request_a, merge_request_d] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by label' do
    let(:search_params) { { labels: [label.title] } }
    let(:mrs) { [merge_request_a, merge_request_c] }

    it_behaves_like 'searching with parameters'
  end

  context 'searching by combination' do
    let(:search_params) { { state: :closed, labels: [label.title] } }
    let(:mrs) { [merge_request_c] }

    it_behaves_like 'searching with parameters'
  end
end
