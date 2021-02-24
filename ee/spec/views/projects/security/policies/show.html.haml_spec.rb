# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/security/policies/show", type: :view do
  let(:user) { project.owner }
  let(:project) { create(:project) }

  before do
    stub_feature_flags(security_orchestration_policies_configuration: true)
    sign_in(user)
    render
  end

  it 'renders the default state' do
    expect(rendered).to have_selector('h2')
    expect(rendered).to have_selector('h4')
    expect(rendered).to have_selector('.js-project-search')
    expect(rendered).to have_selector('.text-muted')
    expect(rendered).to have_selector('.gl-button')
  end
end
