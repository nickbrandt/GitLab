# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/dast_scanner_profiles/new", type: :view do
  before do
    @project = create(:project)
    render
  end

  it 'renders Vue app root' do
    expect(rendered).to have_selector('.js-dast-scanner-profile-form')
  end
end
