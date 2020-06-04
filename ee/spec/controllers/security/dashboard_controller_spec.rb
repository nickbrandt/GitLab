# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::DashboardController do
  describe 'GET #show' do
    it_behaves_like Security::ApplicationController do
      let(:security_application_controller_child_action) do
        get :show
      end
    end
  end
end
