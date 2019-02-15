require 'rails_helper'

describe 'Merge request > User sees approval widget', :js do
  let(:project) { create(:project, :public, :repository, approvals_before_merge: 1) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    stub_feature_flags(approval_rules: false)
  end

  context 'when merge when discussions resolved is active' do
    let(:project) do
      create(:project, :repository,
        approvals_before_merge: 1,
        only_allow_merge_if_all_discussions_are_resolved: true)
    end

    before do
      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'does not show checking ability text' do
      expect(find('.js-mr-approvals')).not_to have_text('Checking ability to merge automatically')
      expect(find('.js-mr-approvals')).to have_selector('.approvals-body')
    end
  end
end
