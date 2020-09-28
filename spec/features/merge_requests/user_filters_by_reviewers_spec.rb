# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by reviewers', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  context 'when merge_request_reviewers is turned false' do
    it 'does not have reviewers filter' do
      stub_feature_flags(merge_request_reviewers: false)
      create(:merge_request, reviewers: [user], title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1')
      create(:merge_request, title: 'Bugfix2', source_project: project, target_project: project, source_branch: 'bugfix2')

      sign_in(user)
      visit project_merge_requests_path(project)

      expect(page).not_to have_content('Reviewer')
    end
  end

  context 'when merge_request_reviewers is turned true' do
    it 'does have reviewers filter' do
      stub_feature_flags(merge_request_reviewers: true)
      create(:merge_request, reviewers: [user], title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1')
      create(:merge_request, title: 'Bugfix2', source_project: project, target_project: project, source_branch: 'bugfix2')

      sign_in(user)
      visit project_merge_requests_path(project)

      expect(page).to have_content('Reviewer')
    end
  end

  # before do
  #   stub_feature_flags(merge_request_reviewers: true)
  #   create(:merge_request, reviewers: [user], title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1')
  #   create(:merge_request, title: 'Bugfix2', source_project: project, target_project: project, source_branch: 'bugfix2')

  #   sign_in(user)
  #   visit project_merge_requests_path(project)
  # end

  # context 'filtering by reviewer:none' do
  #   it 'applies the filter' do
  #     input_filtered_search('reviewer:=none')

  #     expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
  #     expect(page).not_to have_content 'Bugfix1'
  #     expect(page).to have_content 'Bugfix2'
  #   end
  # end

  # context 'filtering by reviewer=@username' do
  #   it 'applies the filter' do
  #     input_filtered_search("reviewer:=@#{user.username}")

  #     expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
  #     expect(page).to have_content 'Bugfix1'
  #     expect(page).not_to have_content 'Bugfix2'
  #   end
  # end
end
