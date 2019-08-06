# frozen_string_literal: true

require 'spec_helper'

describe 'operations/environments.html.haml' do
  it 'renders the frontend configuration' do
    render

    expect(rendered).to match %r{data-add-path="/-/operations"}
    expect(rendered).to match %r{data-list-path="/-/operations/environments_list"}
    expect(rendered).to match %r{data-empty-dashboard-svg-path="/assets/illustrations/operations-dashboard_empty.*\.svg"}
    expect(rendered).to match %r{data-empty-dashboard-help-path="/help/user/operations_dashboard/index.html"}
  end
end
