# frozen_string_literal: true

require 'spec_helper'

shared_examples 'SecurityDashboardsPermissions disabled' do
  include ApiHelpers

  let(:security_dashboard_user) { create(:user) }

  before do
    sign_in(security_dashboard_user)
  end

  describe 'access for all actions' do
    context 'when security dashboard feature is enabled' do
      it 'returns 404' do
        stub_licensed_features(security_dashboard: true)

        security_dashboard_action

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
