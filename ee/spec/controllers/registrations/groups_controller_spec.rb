# frozen_string_literal: true

require 'spec_helper'

describe Registrations::GroupsController do
  let_it_be(:user) { create(:user) }

  describe 'GET #new' do
    subject { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it { is_expected.to render_template(:new) }

      context 'user without the ability to create a group' do
        let(:user) { create(:user, can_create_group: false) }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: { group: params } }

    let(:params) { { name: 'Group name', path: 'group-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      it 'creates a group' do
        expect { subject }.to change { Group.count }.by(1)
      end

      it 'redirects to the group path' do
        expect(subject).to have_gitlab_http_status(:redirect)
        expect(subject).to redirect_to('/group-path')
      end
    end

    context 'when the group cannot be saved' do
      before do
        sign_in(user)
      end

      let(:params) { { name: '', path: '' } }

      it 'does not create a group' do
        expect { subject }.not_to change { Group.count }
        expect(assigns(:group).errors).not_to be_blank
      end

      it 'renders the new template' do
        expect(subject).to have_gitlab_http_status(:ok)
        expect(subject).to render_template(:new)
      end
    end
  end
end
