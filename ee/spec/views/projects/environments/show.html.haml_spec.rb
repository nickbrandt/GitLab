# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "projects/environments/show", type: :view do
  let_it_be(:user) { create(:admin) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    @project = create(:project)
    @environment = create(:environment, project: @project)
    @deployments = @environment.deployments
  end

  context 'when migrate_environment_details_to_vue is enabled' do
    before do
      stub_feature_flags(migrate_environment_details_to_vue: true)
      render
    end

    it 'renders the environment container when feature flag is disabled' do
      expect(rendered).not_to have_selector('.environments-container')
    end
  end

  context 'when migrate_environment_details_to_vue is disabled' do
    before do
      stub_feature_flags(migrate_environment_details_to_vue: false)
      render
    end

    it 'renders the environment container when feature flag is disabled' do
      expect(rendered).to have_selector('.environments-container')
    end
  end
end
