# frozen_string_literal: true

require 'spec_helper'

describe Security::ProjectsController do
  describe 'GET #index' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        get :index
      end
    end
  end

  describe 'POST #create' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        post :create
      end
    end
  end

  describe 'DELETE #destroy' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        delete :destroy, params: { id: 1 }
      end
    end
  end
end
