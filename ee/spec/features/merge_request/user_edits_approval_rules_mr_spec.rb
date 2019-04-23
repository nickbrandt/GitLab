# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User edits MR with approval rules', :js do
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
end
