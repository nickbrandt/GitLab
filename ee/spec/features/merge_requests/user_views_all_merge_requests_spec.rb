# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views all merge requests' do
  let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:project) { create(:project, :public, approvals_before_merge: 1) }
  let(:user) { create(:user) }

  it 'shows generic approvals tooltip' do
    visit(project_merge_requests_path(project, state: :all))
    expect(page.all('li').any? { |item| item["title"] == "Approvals"}).to be true
  end

  it 'shows custom tooltip after user has approved' do
    project.add_developer(user)
    sign_in(user)
    merge_request.approvals.create(user: user)
    visit(project_merge_requests_path(project, state: :all))
    expect(page.all('li').any? { |item| item["title"] == "Approvals (you've approved)"}).to be true
  end
end
