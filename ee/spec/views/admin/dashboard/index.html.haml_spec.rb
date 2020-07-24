# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/dashboard/index.html.haml' do
  include Devise::Test::ControllerHelpers

  before do
    counts = Admin::DashboardController::COUNTED_ITEMS.each_with_object({}) do |item, hash|
      hash[item] = 100
    end

    assign(:counts, counts)
    assign(:projects, create_list(:project, 1))
    assign(:users, create_list(:user, 1))
    assign(:groups, create_list(:group, 1))
    assign(:license, create(:license))

    allow(view).to receive(:admin?).and_return(true)
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
    allow(view).to receive(:show_license_breakdown?).and_return(true)
  end

  it 'includes notices above license breakdown' do
    assign(:notices, [{ type: :alert, message: 'An alert' }])

    render

    expect(rendered).to have_content /An alert.*Users in License/
  end

  it 'includes license breakdown' do
    render

    expect(rendered).to have_content "Users in License"
    expect(rendered).to have_content "Active Users"
    expect(rendered).to have_content "Maximum Users"
    expect(rendered).to have_content "Users over License"
  end
end
