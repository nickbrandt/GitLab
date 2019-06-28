# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::VulnerabilitiesController do
  include ApiHelpers

  it_behaves_like VulnerabilitiesActions

  set(:group) { create(:group) }
  set(:user) { create(:user) }

  describe 'permissions for all actions' do
    before do
      sign_in(user)
      stub_licensed_features(security_dashboard: true)
    end

    subject { get :index, params: { group_id: group }, format: :json }

    context 'when user has guest access' do
      before do
        group.add_guest(user)
      end

      it 'denies access' do
        subject

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when user has developer access' do
      before do
        group.add_guest(user)
      end

      it 'grants access' do
        subject

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end
end
