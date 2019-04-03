# frozen_string_literal: true

require 'rails_helper'

describe 'Merge request > User sets approval rules', :js do
  include ProjectForksHelper

  let(:approver) { create(:user) }
  let(:author) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  def page_rule_names
    page.all('.js-approval-rules table .js-name')
  end

  before do
    stub_licensed_features(multiple_approval_rules: true)

    [approver, author].each do |member|
      project.add_maintainer(member)
    end
  end

  context "with project approval rules" do
    let!(:regular_rules) do
      Array.new(3) do |i|
        create(:approval_project_rule, project: project, users: [approver], name: "Regular Rule #{i}")
      end
    end

    context "from a fork" do
      let(:forked_project) { fork_project(project, nil, repository: true) }

      before do
        forked_project.add_maintainer(author)
        allow(forked_project).to receive(:multiple_approval_rules_available?).and_return(false)

        sign_in(author)
        visit project_new_merge_request_path(forked_project, merge_request: { target_branch: 'master', target_project_id: project.id, source_branch: 'feature' })
        wait_for_requests
      end

      it "shows approval rules from target project" do
        names = page_rule_names
        regular_rules.each_with_index do |rule, idx|
          expect(names[idx]).to have_text(rule.name)
        end
      end
    end

    context "with a private group rule" do
      let!(:private_group) { create(:group, :private) }
      let!(:private_rule) { create(:approval_project_rule, project: project, groups: [private_group], name: 'Private Rule') }
      let!(:rules) { regular_rules + [private_rule] }

      before do
        private_group.add_developer(approver)

        sign_in(author)
        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })
        wait_for_requests
      end

      it "shows approval rules" do
        names = page_rule_names
        rules.each.with_index do |rule, idx|
          expect(names[idx]).to have_text(rule.name)
        end
      end

      it "persists hidden groups that author has no access to when creating MR" do
        click_on("Submit merge request")
        wait_for_requests

        click_on("View eligible approvers")
        wait_for_requests

        tr = page.find(:css, 'tr', text: private_rule.name)
        expect(tr).to have_selector('.js-approvers a.user-avatar-link')
      end
    end
  end
end
