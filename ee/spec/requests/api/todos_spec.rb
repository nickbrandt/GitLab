# frozen_string_literal: true

require 'spec_helper'

describe API::Todos do
  set(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  set(:project) { create(:project, group: group) }

  describe 'GET /todos' do
    let(:author_1) { create(:user) }
    let!(:pat) { create(:personal_access_token, user: user) }

    before do
      group.add_developer(user)
      group.add_developer(author_1)
    end

    def create_todo_for_new_epic
      new_group = create(:group)
      label = create(:label)
      new_epic = create(:labeled_epic, group: new_group, labels: [label])
      new_group.add_developer(author_1)
      new_group.add_developer(user)
      create(:todo, project: nil, group: new_group, author: author_1, user: user, target: new_epic)
    end

    def create_todo_for_mentioned_in_design
      issue = create(:issue, project: project)
      create(:todo, :mentioned,
             user: user,
             project: project,
             target: create(:design, issue: issue),
             author: create(:user),
             note: create(:note, project: project, note: "I am note, hear me roar"))
    end

    shared_examples 'an endpoint that responds with success' do
      it do
        expect(response.status).to eq(200)
      end
    end

    context 'when there is an Epic Todo' do
      let!(:epic_todo) { create_todo_for_new_epic }

      before do
        get api('/todos', personal_access_token: pat)
      end

      it_behaves_like 'an endpoint that responds with success'

      it 'avoids N+1 queries', :request_store do
        create_todo_for_new_epic

        control = ActiveRecord::QueryRecorder.new { get api('/todos', personal_access_token: pat) }

        create_todo_for_new_epic

        expect { get api('/todos', personal_access_token: pat) }.not_to exceed_query_limit(control)
      end

      it 'includes the Epic Todo in the response' do
        expect(json_response).to include(
          a_hash_including('id' => epic_todo.id)
        )
      end
    end

    context 'when there is a Design Todo' do
      let!(:design_todo) { create_todo_for_mentioned_in_design }

      def api_request
        get api('/todos', personal_access_token: pat)
      end

      context 'when the feature is enabled' do
        before do
          api_request
        end

        it_behaves_like 'an endpoint that responds with success'

        it 'avoids N+1 queries', :request_store do
          control = ActiveRecord::QueryRecorder.new { api_request }

          create_todo_for_mentioned_in_design

          expect { api_request }.not_to exceed_query_limit(control)
        end

        it 'includes the Design Todo in the response' do
          expect(json_response).to include(
            a_hash_including('id' => design_todo.id)
          )
        end
      end

      context 'when the feature is disabled' do
        before do
          stub_feature_flags(design_management_todos_api: false)
          api_request
        end

        it_behaves_like 'an endpoint that responds with success'

        it 'does not include the Design Todo in the response' do
          expect(json_response).to be_empty
        end
      end
    end
  end

  describe 'POST :id/epics/:epic_iid/todo' do
    subject { post api("/groups/#{group.id}/epics/#{epic.iid}/todo", user) }

    context 'when epics feature is disabled' do
      it 'returns 403 forbidden error' do
        subject

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'creates a todo on an epic' do
        expect { subject }.to change { Todo.count }.by(1)

        expect(response.status).to eq(201)
        expect(json_response['project']).to be_nil
        expect(json_response['group']).to be_a(Hash)
        expect(json_response['author']).to be_a(Hash)
        expect(json_response['target_type']).to eq('Epic')
        expect(json_response['target']).to be_a(Hash)
        expect(json_response['target_url']).to be_present
        expect(json_response['body']).to be_present
        expect(json_response['state']).to eq('pending')
        expect(json_response['action_name']).to eq('marked')
        expect(json_response['created_at']).to be_present
      end

      it 'returns 304 there already exist a todo on that epic' do
        create(:todo, project: nil, group: group, user: user, target: epic)

        subject

        expect(response.status).to eq(304)
      end

      it 'returns 404 if the epic is not found' do
        post api("/groups/#{group.id}/epics/9999/todo", user)

        expect(response.status).to eq(403)
      end

      it 'returns an error if the epic is not accessible' do
        group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
