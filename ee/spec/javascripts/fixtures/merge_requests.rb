# frozen_string_literal: true

require 'spec_helper'

describe Projects::MergeRequestsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures' )}
  let(:project) { create(:project, :repository, namespace: namespace, path: 'merge-requests-project') }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: admin, approvals_before_merge: 2) }
  let(:suggested_approvers) do
    create_list(:user, 3).tap do |users|
      users.each { |user| project.add_developer(user) }
    end
  end

  render_views

  before(:all) do
    clean_frontend_fixtures('merge_requests_ee/')
  end

  before do
    # Ensure some approver suggestions are displayed
    service = double(:service)
    expect(::Gitlab::AuthorityAnalyzer).to receive(:new).and_return(service)
    expect(service).to receive(:calculate).and_return(suggested_approvers)

    # Ensure a project level group is present (but unsaved)
    approver_group = create(:approver_group, target: project)
    approver_group.group.add_owner(create(:owner))

    sign_in(admin)
  end

  after do
    remove_repository(project)
  end

  it 'merge_requests_ee/merge_request_edit.html.raw' do |example|
    get :edit,
      params: {
        id: merge_request.id,
        namespace_id: project.namespace.to_param,
        project_id: project
      },
      format: :html

    expect(merge_request.all_approvers_including_groups.size).to eq(1)
    expect(response).to be_success
    store_frontend_fixture(response, example.description)
  end
end
