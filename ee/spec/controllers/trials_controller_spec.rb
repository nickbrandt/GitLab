# frozen_string_literal: true

require 'spec_helper'

describe TrialsController do
  shared_examples 'an authenticated endpoint' do |verb, action|
    it 'redirects to login page' do
      send(verb, action)

      expect(response).to redirect_to(new_trial_registration_url)
    end
  end

  before do
    allow(::Gitlab).to receive(:com?).and_return(true)
    stub_feature_flags(improved_trial_signup: true)
  end

  describe '#new' do
    it_behaves_like 'an authenticated endpoint', :get, :new

    context 'when invalid - instance is not GL.com' do
      it 'returns 404 not found' do
        allow(::Gitlab).to receive(:com?).and_return(false)

        get :new

        expect(response.status).to eq(404)
      end
    end

    context 'when feature is turned off' do
      it 'returns 404 not found' do
        stub_feature_flags(improved_trial_signup: false)

        get :new

        expect(response.status).to eq(404)
      end
    end
  end

  describe '#create_lead' do
    it_behaves_like 'an authenticated endpoint', :post, :create_lead

    describe 'authenticated' do
      let(:user) { create(:user) }
      let(:create_lead_result) { nil }

      before do
        sign_in(user)

        expect_any_instance_of(GitlabSubscriptions::CreateLeadService).to receive(:execute) do
          { success: create_lead_result }
        end
      end

      context 'on success' do
        let(:create_lead_result) { true }

        it 'redirects user to Step 3' do
          post :create_lead

          expect(response).to redirect_to(select_trials_url)
        end
      end

      context 'on failure' do
        let(:create_lead_result) { false }

        it 'renders the :new template' do
          post :create_lead

          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe '#select' do
    it_behaves_like 'an authenticated endpoint', :get, :select
  end

  describe '#apply' do
    let(:user) { create(:user) }
    let(:namespace) { create(:namespace, owner_id: user.id, path: 'namespace-test') }
    let(:apply_trial_result) { nil }

    before do
      sign_in(user)

      allow_any_instance_of(GitlabSubscriptions::ApplyTrialService).to receive(:execute) do
        { success: apply_trial_result }
      end
    end

    context 'on success' do
      let(:apply_trial_result) { true }

      it "redirects to group's path with the parameter trial as true" do
        post :apply, params: { namespace_id: namespace.id }

        expect(response).to redirect_to("/#{namespace.path}?trial=true")
      end

      context 'with a new Group' do
        it 'creates the Group' do
          expect do
            post :apply, params: { new_group_name: 'GitLab' }
          end.to change { Group.count }.to(1)
        end
      end
    end

    context 'on failure' do
      let(:apply_trial_result) { false }

      it 'renders the :select view' do
        post :apply, params: { namespace_id: namespace.id }

        expect(response).to render_template(:select)
      end

      context 'with a new Group' do
        it 'renders the :select view' do
          post :apply, params: { new_group_name: 'admin' }

          expect(response).to render_template(:select)
          expect(Group.count).to eq(0)
        end
      end
    end
  end
end
