# frozen_string_literal: true

require 'spec_helper'

describe API::VisualReviewDiscussions do
  let(:user)     { create(:user) }
  let!(:project) { create(:project, :public, :repository, namespace: user.namespace) }

  context 'when sending merge request feedback from a visual review app without authentication' do
    let!(:merge_request) do
      create(:merge_request_with_diffs, source_project: project, target_project: project, author: user)
    end

    let(:request) do
      post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/visual_review_discussions"), params: note_params
    end

    let(:note_params)   { { body: 'hi!' } }
    let(:response_note) { json_response['notes'].first }

    it 'creates a new note' do
      expect { request }.to change(merge_request.notes, :count).by(1)
    end

    describe 'the API response' do
      before do
        request
      end

      it 'responds with a status 201 Created' do
        expect(response).to have_gitlab_http_status(201)
      end

      it 'returns the persisted note body' do
        expect(response_note['body']).to eq('hi!')
      end

      it 'returns the name of the Visual Review Bot assigned as the author' do
        expect(response_note['author']['username']).to eq(User.visual_review_bot.username)
      end

      it 'returns the id of the merge request as the parent noteable_id' do
        expect(response_note['noteable_id']).to eq(merge_request.id)
      end
    end

    context 'with no message body' do
      let(:note_params) { { some: 'thing' } }

      it 'returns a 400 bad request error if body not given' do
        expect { request }.not_to change(merge_request.notes, :count)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'with an invalid merge request IID' do
      let(:merge_request) { double(iid: 546574823564) }

      it 'creates a new note' do
        expect { request }.not_to change(Note, :count)
      end

      describe 'the API response' do
        it 'responds with a status 404' do
          request

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when anonymous_visual_review_feedback feature flag is disabled' do
      before do
        stub_feature_flags(anonymous_visual_review_feedback: false)
      end

      it 'does not create a new note' do
        expect { request }.not_to change(merge_request.notes, :count)
      end

      describe 'the API response' do
        before do
          request
        end

        it 'responds 403' do
          expect(response).to have_gitlab_http_status(403)
        end

        it 'returns error messaging specifying that the feature is disabled' do
          expect(json_response['message']).to eq('403 Forbidden  - Anonymous visual review feedback is disabled')
        end
      end
    end

    context 'when an admin or owner makes an authenticated request' do
      let(:request) do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/visual_review_discussions", project.owner), params: note_params
      end

      let(:note_params) { { body: 'hi!', created_at: 2.weeks.ago } }

      it 'creates a new note' do
        expect { request }.to change(merge_request.notes, :count).by(1)
      end

      describe 'the API response' do
        before do
          request
        end

        it 'responds with a status 201 Created' do
          expect(response).to have_gitlab_http_status(201)
        end

        it 'returns the persisted note body' do
          expect(response_note['body']).to eq('hi!')
        end

        it 'returns the name of the Visual Review Bot assigned as the author' do
          expect(response_note['author']['username']).to eq(User.visual_review_bot.username)
        end

        it 'returns the id of the merge request as the parent noteable_id' do
          expect(response_note['noteable_id']).to eq(merge_request.id)
        end

        it 'returns a current time stamp instead of the provided one' do
          expect(Time.parse(response_note['created_at']) > 1.day.ago).to eq(true)
        end
      end
    end
  end
end
