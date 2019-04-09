# frozen_string_literal: true

require "spec_helper"

describe "User creates a merge request", :js do
  include ProjectForksHelper

  let(:approver) { create(:user) }
  let(:project) do
    create(:project,
      :repository,
      approvals_before_merge: 1,
      merge_requests_template: template_text)
  end
  let(:template_text) { "This merge request should contain the following." }
  let(:title) { "Some feature" }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  before do
    stub_feature_flags(approval_rules: false)

    project.add_maintainer(user)
    project.add_maintainer(user2)
    project.add_maintainer(approver)
    sign_in(user)

    project.approvers.create(user_id: approver.id)

    visit(project_new_merge_request_path(project))
  end

  it "creates a merge request" do
    allow_any_instance_of(Gitlab::AuthorityAnalyzer).to receive(:calculate).and_return([user2])

    find(".js-source-branch").click
    click_link("fix")

    find(".js-target-branch").click
    click_link("feature")

    click_button("Compare branches")

    expect(find_field("merge_request_description").value).to eq(template_text)

    page.within("ul .unsaved-approvers") do
      expect(page).to have_content(approver.name)
    end

    page.within(".suggested-approvers") do
      expect(page).to have_content(user2.name)
    end

    click_link(user2.name)

    page.within("ul.approver-list") do
      expect(page).to have_content(user2.name)
    end

    fill_in("Title", with: title)
    click_button("Submit merge request")

    page.within(".js-issuable-actions") do
      click_link("Edit", match: :first)
    end

    page.within("ul.approver-list") do
      expect(page).to have_content(user2.name)
    end
  end
end
