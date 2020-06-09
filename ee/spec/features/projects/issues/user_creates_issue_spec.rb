# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User creates issue", :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project_empty_repo, :public, namespace: group) }
  let!(:epic) { create(:epic, group: group, title: 'Sample epic', author: user) }

  before do
    stub_licensed_features(issue_weights: true)
    stub_licensed_features(epics: true)

    group.add_developer(user)
    sign_in(user)

    visit(new_project_issue_path(project))
  end

  context "with weight set" do
    it "creates issue" do
      issue_title = "500 error on profile"
      weight = "7"

      fill_in("Title", with: issue_title)
      fill_in("issue_weight", with: weight)

      click_button("Submit issue")

      page.within(".weight") do
        expect(page).to have_content(weight)
      end

      expect(page).to have_content(issue_title)
    end
  end

  context "with epic set" do
    it "creates issue" do
      issue_title = "500 error on profile"

      fill_in("Title", with: issue_title)
      page.within('.issue-epic .js-epic-block') do
        page.find('.js-epic-select').click
        wait_for_requests

        page.find('.dropdown-content .gl-link', text: epic.title).click
      end

      click_button("Submit issue")

      wait_for_all_requests

      page.within(".js-epic-block .js-epic-label") do
        expect(page).to have_content(epic.title)
      end

      expect(page).to have_content(issue_title)
    end
  end
end
