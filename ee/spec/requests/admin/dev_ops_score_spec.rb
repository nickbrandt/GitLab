# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin dev ops analytics' do
  let(:user) { create(:admin) }

  before do
    login_as(user)
  end

  it 'redirects from -/analytics to admin/dev_ops_score' do
    get '/-/analytics'

    expect(response).to redirect_to(admin_dev_ops_score_path)
  end
end
