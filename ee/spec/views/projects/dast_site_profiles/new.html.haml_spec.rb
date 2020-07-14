# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/dast_site_profiles/new", type: :view do
  before do
    @project = create(:project)
    render
  end

  it 'renders a placeholder title' do
    expect(rendered).to have_content('New Site Profile')
  end
end
