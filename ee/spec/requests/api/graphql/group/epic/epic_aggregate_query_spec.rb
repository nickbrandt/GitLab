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

  context 'count and weight totals' do
    subject { graphql_data.dig('group', 'epics', 'nodes') }

    let_it_be(:subgroup) { create(:group, :private, parent: group)}
    let_it_be(:subsubgroup) { create(:group, :private, parent: subgroup)}

    let_it_be(:project) { create(:project, namespace: group) }

    let_it_be(:epic_with_issues) { create(:epic, id: 2, group: subgroup, parent: parent_epic, title: 'epic with issues') }
    let_it_be(:epic_without_issues) { create(:epic, :closed, id: 3, group: subgroup, parent: parent_epic, title: 'epic without issues') }
    let_it_be(:closed_epic) { create(:epic, :closed, id: 4, group: subgroup, parent: parent_epic, title: 'closed epic') }

    let_it_be(:issue1) { create(:issue, project: project, weight: 5, state: :opened) }
    let_it_be(:issue2) { create(:issue, project: project, weight: 7, state: :closed) }

    let_it_be(:epic_issue1) { create(:epic_issue, epic: epic_with_issues, issue: issue1) }
    let_it_be(:epic_issue2) { create(:epic_issue, epic: epic_with_issues, issue: issue2) }

    before do
      group.add_developer(current_user)
      post_graphql(query, current_user: current_user)
    end

    shared_examples 'counts properly' do
      it_behaves_like 'a working graphql query'

      it 'returns the epic counts' do
        epic_count_result = {
          "openedEpics" => 1,
          "closedEpics" => 2
        }

        is_expected.to include(
          a_hash_including('descendantCounts' => a_hash_including(epic_count_result))
        )
      end

      it 'returns the issue counts' do
        issue_count_result = {
          "openedIssues" => 1,
          "closedIssues" => 1
        }

        is_expected.to include(
          a_hash_including('descendantCounts' => a_hash_including(issue_count_result))
        )
      end
    end

    context 'with feature flag enabled' do
      before do
        stub_feature_flags(unfiltered_epic_aggregates: true)
      end

      it 'uses the LazyEpicAggregate service' do
        # one for count, one for weight_sum, even though the share the same tree state as part of the context
        expect(Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate).to receive(:new).twice

        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'counts properly'

      it 'returns the weights' do
        descendant_weight_result = {
            "openedIssues" => 5,
            "closedIssues" => 7
        }

        is_expected.to include(
          a_hash_including('descendantWeightSum' => a_hash_including(descendant_weight_result))
        )
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

        it_behaves_like 'counts properly'
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

        it 'returns nil' do
          post_graphql(query, current_user: current_user)

          expect(subject).to include(a_hash_including('descendantWeightSum' => nil))
        end
      end
    end
  end
end
