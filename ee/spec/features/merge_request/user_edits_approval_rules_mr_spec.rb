# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User edits MR with approval rules', :js do
  include Select2Helper

  include_context 'project with approval rules'

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:mr_rule_names) { %w[foo lorem ipsum] }

  def page_rule_names
    page.all('.js-approval-rules table .js-name')
  end

  before do
    project.update_attribute(:disable_overriding_approvers_per_merge_request, false)
    stub_licensed_features(multiple_approval_rules: true)

    mr_rule_names.each do |name|
      create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1, name: name)
    end

    sign_in(author)
    visit(edit_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it "shows approval rules" do
    names = page_rule_names.map(&:text)

    expect(names).to eq(mr_rule_names)
  end

  context "with public group" do
    let!(:group) { create(:group, :public) }

    before do
      group.add_developer create(:user)
    end

    it "can be added by non member" do
      members_selector = '#mr-edit-approvals-create-modal input[name=members]'
      rule_name = "Custom Approval Rule"

      click_button "Add approvers"

      fill_in "Name", with: rule_name

      open_select2 members_selector
      find('.select2-result-label .group-result', text: group.name).click
      close_select2 members_selector

      find('#mr-edit-approvals-create-modal button', text: 'Add', exact_text: true).click

      find('#mr-edit-approvals-create-modal button', text: 'Add approvers').click

      wait_for_requests

      expect(page_rule_names.last).to have_text(rule_name)
    end
  end
end
