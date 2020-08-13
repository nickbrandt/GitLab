# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::BillingsController do
  let_it_be(:user)  { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  describe 'GET index' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
    end

    def get_index
      get :index, params: { group_id: group }
    end

    def add_group_owner
      group.add_owner(user)
    end

    subject { response }

    context 'authorized' do
      before do
        add_group_owner
        allow_next_instance_of(FetchSubscriptionPlansService) do |instance|
          allow(instance).to receive(:execute)
        end
      end

      it 'renders index with 200 status code' do
        get_index

        is_expected.to have_gitlab_http_status(:ok)
        is_expected.to render_template(:index)
      end

      it 'fetches subscription plans data from customers.gitlab.com' do
        data = double
        expect_next_instance_of(FetchSubscriptionPlansService) do |instance|
          expect(instance).to receive(:execute).and_return(data)
        end

        get_index

        expect(assigns(:plans_data)).to eq(data)
      end
    end

    context 'unauthorized' do
      it 'renders 404 when user is not an owner' do
        group.add_developer(user)

        get_index

        is_expected.to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 when it is not gitlab.com' do
        add_group_owner
        expect(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).at_least(:once) { false }

        get_index

        is_expected.to have_gitlab_http_status(:not_found)
      end
    end
  end
end
