# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CycleAnalyticsController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders `show` template' do
      get :show

      expect(response).to render_template :show
    end
  end
end
