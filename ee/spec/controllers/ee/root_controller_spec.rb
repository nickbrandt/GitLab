# frozen_string_literal: true

require 'spec_helper'

describe RootController do
  describe 'GET index' do
    let(:user) { create(:user) }

    before do
      stub_licensed_features(operations_dashboard: true)
      sign_in(user)
      allow(subject).to receive(:current_user).and_return(user)
    end

    context 'who has customized their dashboard setting for operations' do
      before do
        user.dashboard = 'operations'
      end

      it 'redirects to operations dashboard' do
        get :index

        expect(response).to redirect_to operations_path
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(operations_dashboard: false)
        end

        it 'renders the default dashboard' do
          get :index

          expect(response).to render_template 'dashboard/projects/index'
        end
      end
    end
  end
end
