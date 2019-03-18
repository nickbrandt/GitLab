# frozen_string_literal: true

require 'spec_helper'

describe Snippets::NotesController do
  let(:user) { create(:user) }

  let(:private_snippet)  { create(:personal_snippet, :private) }
  let(:internal_snippet) { create(:personal_snippet, :internal) }
  let(:public_snippet)   { create(:personal_snippet, :public) }
  let(:secret_snippet)   { create(:personal_snippet, :secret) }

  let(:note_on_private)  { create(:note_on_personal_snippet, noteable: private_snippet) }
  let(:note_on_internal) { create(:note_on_personal_snippet, noteable: internal_snippet) }
  let(:note_on_public)   { create(:note_on_personal_snippet, noteable: public_snippet) }
  let(:note_on_secret)   { create(:note_on_personal_snippet, noteable: secret_snippet) }

  describe 'GET index' do
    let(:snippet_params) { { snippet_id: snippet } }
    let(:params) { snippet_params}

    subject { get :index, params: params }

    context 'when a snippet is public' do
      let(:snippet) { public_snippet }

      before do
        note_on_public

        subject
      end

      it 'returns status 200' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns not empty array of notes' do
        expect(json_response["notes"].empty?).to be_falsey
      end
    end

    context 'when a snippet is secret' do
      let(:snippet) { secret_snippet }
      let(:flag_value) { true }

      before do
        note_on_secret

        stub_feature_flags(secret_snippets: flag_value)

        subject
      end

      context 'when token is not present' do
        it 'returns status 404' do
          expect(response).to have_gitlab_http_status(404)
        end

        context 'when secret_snippets flag is disabled' do
          let(:flag_value) { false }

          it 'returns status 200' do
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'when token is invalid' do
        let(:params) { snippet_params.merge(token: 'foo') }

        it 'returns status 404' do
          expect(response).to have_gitlab_http_status(404)
        end

        context 'when secret_snippets flag is disabled' do
          let(:flag_value) { false }

          it 'returns status 200' do
            expect(response).to have_gitlab_http_status(200)
          end
        end
      end

      context 'when token is present' do
        let(:params) { snippet_params.merge(token: snippet.secret_token) }

        it 'returns status 200' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'returns not empty array of notes' do
          expect(json_response['notes'].empty?).to be_falsey
        end
      end
    end

    context 'when a snippet is internal' do
      let(:snippet) { internal_snippet }

      before do
        note_on_internal
      end

      context 'when user not logged in' do
        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when user logged in' do
        before do
          sign_in(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'when a snippet is private' do
      let(:snippet) { private_snippet }

      before do
        note_on_private
      end

      context 'when user not logged in' do
        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when user other than author logged in' do
        before do
          sign_in(user)
        end

        it 'returns status 404' do
          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when author logged in' do
        before do
          note_on_private

          sign_in(snippet.author)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(200)
        end

        it 'returns 1 note' do
          subject

          expect(json_response['notes'].count).to eq(1)
        end
      end
    end

    context 'dont show non visible notes' do
      let(:snippet) { public_snippet }

      before do
        note_on_public

        sign_in(user)

        expect_any_instance_of(Note).to receive(:cross_reference_not_visible_for?).and_return(true)
      end

      it 'does not return any note' do
        subject

        expect(json_response['notes'].count).to eq(0)
      end
    end
  end

  describe 'POST create' do
    let(:snippet_params) do
      {
        note: attributes_for(:note_on_personal_snippet, noteable: snippet),
        snippet_id: snippet.id
      }
    end
    let(:request_params) { snippet_params }

    subject { post :create, params: request_params }

    before do
      sign_in user
    end

    shared_examples 'creates the note' do
      it 'returns status 302' do
        subject

        expect(response).to have_gitlab_http_status(302)
      end

      it 'creates the note' do
        expect { subject }.to change { Note.count }.by(1)
      end
    end

    shared_examples 'does not create the note' do
      it 'returns status 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end

      it 'does not create the note' do
        expect { subject }.not_to change { Note.count }
      end
    end

    context 'when a snippet is public' do
      let(:snippet) { public_snippet }

      it_behaves_like 'creates the note'
    end

    context 'when a snippet is secret' do
      let(:snippet) { secret_snippet }

      context 'when token is not present' do
        it_behaves_like 'does not create the note'
      end

      context 'when token is not valid' do
        let(:request_params) { snippet_params.merge(token: 'foo') }

        it_behaves_like 'does not create the note'
      end

      context 'when token is valid' do
        let(:request_params) { snippet_params.merge(token: snippet.secret_token) }

        it_behaves_like 'creates the note'
      end
    end

    context 'when a snippet is internal' do
      let(:snippet) { internal_snippet }

      it_behaves_like 'creates the note'
    end

    context 'when a snippet is private' do
      let(:snippet) { private_snippet }

      context 'when user is not the author' do
        it_behaves_like 'does not create the note'

        context 'when user sends a snippet_id for a public snippet' do
          let(:request_params) { snippet_params.merge(snippet_id: public_snippet.id) }

          it_behaves_like 'creates the note'
        end
      end

      context 'when user is the author' do
        let(:user) { private_snippet.author }

        it_behaves_like 'creates the note'
      end
    end
  end

  describe 'DELETE destroy' do
    let(:request_params) do
      {
        snippet_id: public_snippet,
        id: note_on_public,
        format: :js
      }
    end

    context 'when user is the author of a note' do
      before do
        sign_in(note_on_public.author)
      end

      it "returns status 200" do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(200)
      end

      it "deletes the note" do
        expect { delete :destroy, params: request_params }.to change { Note.count }.from(1).to(0)
      end

      context 'system note' do
        before do
          expect_any_instance_of(Note).to receive(:system?).and_return(true)
        end

        it "does not delete the note" do
          expect { delete :destroy, params: request_params }.not_to change { Note.count }
        end
      end
    end

    context 'when user is not the author of a note' do
      before do
        sign_in(user)

        note_on_public
      end

      it "returns status 404" do
        delete :destroy, params: request_params

        expect(response).to have_gitlab_http_status(404)
      end

      it "does not update the note" do
        expect { delete :destroy, params: request_params }.not_to change { Note.count }
      end
    end
  end

  describe 'POST toggle_award_emoji' do
    let(:snippet) { public_snippet }
    let(:note) { create(:note_on_personal_snippet, noteable: snippet) }
    let(:emoji_name) { 'thumbsup'}
    let(:snippet_params) { { snippet_id: snippet, id: note.id, name: emoji_name } }
    let(:params) { snippet_params }

    before do
      sign_in(user)
    end

    subject { post(:toggle_award_emoji, params: params) }

    shared_examples 'toggles/removes award emoji' do
      it 'toggles the award emoji' do
        expect { subject }.to change { note.award_emoji.count }.by(1)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'removes the already awarded emoji when it exists' do
        create(:award_emoji, awardable: note, name: emoji_name, user: user)

        expect { subject }.to change { AwardEmoji.count }.by(-1)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    it_behaves_like 'toggles/removes award emoji'

    context 'when snippet is secret' do
      let(:snippet) { secret_snippet }

      context 'when token is not present' do
        it 'returns status 404' do
          expect(subject).to have_gitlab_http_status(404)
        end
      end

      context 'when token is invalid' do
        let(:params) { snippet_params.merge(token: 'foo') }

        it 'returns status 404' do
          expect(subject).to have_gitlab_http_status(404)
        end
      end

      context 'when token is valid' do
        let(:params) { snippet_params.merge(token: snippet.secret_token) }

        it_behaves_like 'toggles/removes award emoji'
      end
    end
  end
end
