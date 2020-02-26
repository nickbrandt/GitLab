# frozen_string_literal: true

require 'spec_helper'

describe 'Epic aggregates (count and weight)' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:parent_epic) { create(:epic, id: 1, group: group, title: 'parent epic') }

  let(:query) do
    graphql_query_for('group', { fullPath: group.full_path }, query_graphql_field('epics', { iid: parent_epic.iid }, epic_aggregates_query))
  end

  let(:epic_aggregates_query) do
    <<~QUERY
        nodes {
          descendantWeightSum {
            openedIssues
            closedIssues
          }
          descendantCounts {
            openedEpics
            closedEpics
            openedIssues
            closedIssues
          }
        }
    QUERY
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'with feature flag enabled' do
    before do
      stub_feature_flags(unfiltered_epic_aggregates: true)
    end

    it 'returns a placeholder with -1 weights and does not error' do
      post_graphql(query, current_user: current_user)

      actual_result = graphql_data.dig('group', 'epics', 'nodes').first
      expected_result = {
        "descendantWeightSum" => {
          "openedIssues" => -1,
          "closedIssues" => -1
        }
      }

      expect(actual_result).to include expected_result
    end
  end

  context 'with feature flag disabled' do
    before do
      stub_feature_flags(unfiltered_epic_aggregates: false)
    end

    context 'when requesting counts' do
      let(:epic_aggregates_query) do
        <<~QUERY
        nodes {
          descendantCounts {
            openedEpics
            closedEpics
            openedIssues
            closedIssues
          }
        }
        QUERY
      end

      it 'uses the DescendantCountService' do
        expect(Epics::DescendantCountService).to receive(:new)

        post_graphql(query, current_user: current_user)
      end
    end

    context 'when requesting weights' do
      let(:epic_aggregates_query) do
        <<~QUERY
        nodes {
          descendantWeightSum {
            openedIssues
            closedIssues
          }
        }
        QUERY
      end

      it 'returns an error' do
        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_include /Field 'descendantWeightSum' doesn't exist on type 'Epic/
      end
    end
  end
end
