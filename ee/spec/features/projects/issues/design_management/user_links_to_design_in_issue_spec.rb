# frozen_string_literal: true

require 'spec_helper'

describe 'viewing issues with design references' do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:design_issue) { create(:issue, project: project) }
  let_it_be(:design_a) { create(:design, :with_file, issue: design_issue) }
  let_it_be(:design_b) { create(:design, :with_file, issue: design_issue) }

  let(:issue) { create(:issue, project: project, description: description) }

  let(:description) do
    <<~MD
    Designs:

    * #{design_a.to_reference(project)}
    * #{design_b.to_reference(project)}
    MD
  end

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'design management is enabled' do
    before do
      enable_design_management
    end

    it 'shows the issue description' do
      visit project_issue_path(project, issue)

      expect(page).to have_link(design_a.to_reference)
      expect(page).to have_link(design_b.to_reference)
    end
  end

  context 'design management is disabled' do
    before do
      enable_design_management(false, false)
    end

    it 'shows the issue description' do
      visit project_issue_path(project, issue)

      expect(page).to have_link(issue.to_reference)
      expect(page).not_to have_link(design_a.to_reference)
      expect(page).not_to have_link(design_b.to_reference)
    end
  end
end
