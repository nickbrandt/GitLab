# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::BillingsController do
  let(:user)  { create(:user) }
  let(:group) { create(:group, :private) }

  describe 'GET index' do
    before do
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
    end

    context 'authorized' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it 'renders index with 200 status code' do
        allow_any_instance_of(FetchSubscriptionPlansService).to receive(:execute)

        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end

      it 'fetches subscription plans data from customers.gitlab.com' do
        data = double
        expect_any_instance_of(FetchSubscriptionPlansService).to receive(:execute).and_return(data)

        get :index, params: { group_id: group }

        expect(assigns(:plans_data)).to eq(data)
      end
    end

    context 'unauthorized' do
      it 'renders 404 when user is not an owner' do
        group.add_developer(user)
        sign_in(user)

        get :index, params: { group_id: group.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 when it is not gitlab.com' do
        expect(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).at_least(:once) { false }
        group.add_owner(user)
        sign_in(user)

        get :index, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
