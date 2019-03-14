# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::DashboardController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    subject { get :show, params: { group_id: group.to_param } }

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'and user is allowed to access group security dashboard' do
        before do
          group.add_developer(user)
        end

        it { is_expected.to have_gitlab_http_status(200) }
      end

      context 'when user is not allowed to access group security dashboard' do
        it { is_expected.to have_gitlab_http_status(403) }
      end
    end

    context 'when security dashboard feature is disabled' do
      it { is_expected.to have_gitlab_http_status(404) }
    end
  end
end
