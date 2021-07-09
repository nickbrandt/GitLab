# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reposition and move issue within board lists' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:existing_issue1) { create(:labeled_issue, project: project, relative_position: 10) }
  let_it_be(:existing_issue2) { create(:labeled_issue, project: project, relative_position: 50) }
  let_it_be(:issue1) { create(:labeled_issue, project: project, relative_position: 3) }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:testing) { create(:label, project: project, name: 'Testing') }
  let_it_be(:list1)   { create(:list, board: board, label: development, position: 0) }
  let_it_be(:list2)   { create(:list, board: board, label: testing, position: 1) }

  let(:mutation_class) { Mutations::Boards::Issues::IssueMoveList }
  let(:mutation_name) { mutation_class.graphql_name }
  let(:params) { { board_id: board.to_global_id.to_s, project_path: project.full_path, iid: issue1.iid.to_s } }
  let(:issue_move_params) do
    {
      epic_id: epic.to_global_id.to_s,
      move_before_id: existing_issue2.id,
      move_after_id: existing_issue1.id,
      from_list_id: list1.id,
      to_list_id: list2.id
    }
  end

  before do
    stub_licensed_features(epics: true)
    project.add_maintainer(user)
  end

  context 'when user can admin epic' do
    before do
      group.add_maintainer(user)
    end

    it 'updates issue position and epic' do
      post_graphql_mutation(mutation(params), current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      response_issue = graphql_mutation_response(:issue_move_list)['issue']
      expect(response_issue['iid']).to eq(issue1.iid.to_s)
      expect(response_issue['relativePosition']).to be > existing_issue1.relative_position
      expect(response_issue['relativePosition']).to be < existing_issue2.relative_position
      expect(response_issue['epic']['id']).to eq(epic.to_global_id.to_s)
      expect(response_issue['labels']['nodes'].first['title']).to eq(testing.title)
    end

    context 'when user sets nil epic' do
      let_it_be(:epic_issue) { create(:epic_issue, issue: issue1, epic: epic) }

      let(:issue_move_params) do
        {
          epic_id: nil,
          move_before_id: existing_issue2.id,
          move_after_id: existing_issue1.id
        }
      end

      it 'updates issue position and epic is unassigned' do
        post_graphql_mutation(mutation(params), current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        response_issue = graphql_mutation_response(:issue_move_list)['issue']
        expect(response_issue['iid']).to eq(issue1.iid.to_s)
        expect(response_issue['relativePosition']).to be > existing_issue1.relative_position
        expect(response_issue['relativePosition']).to be < existing_issue2.relative_position
        expect(response_issue['epic']).to be_nil
      end
    end
  end

  context 'when user can not admin epic' do
    it 'fails with error' do
      post_graphql_mutation(mutation(params), current_user: user)

      mutation_response = graphql_mutation_response(:issue_move_list)
      expect(mutation_response['errors']).to eq(['You are not allowed to move the issue'])
      expect(mutation_response['issue']['epic']).to eq(nil)
      expect(mutation_response['issue']['relativePosition']).to eq(3)
    end
  end

  def mutation(additional_params = {})
    graphql_mutation(mutation_name, issue_move_params.merge(additional_params),
                     <<-QL.strip_heredoc
                       clientMutationId
                       issue {
                         iid,
                         relativePosition
                         epic {
                           id
                         }
                         labels {
                           nodes {
                             title
                           }
                         }
                       }
                       errors
                     QL
    )
  end
end
