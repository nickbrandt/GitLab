require 'spec_helper'

describe 'EE > Projects > Settings > User manages approval rule settings' do
  let(:project) { create(:project) }
  let(:user) { project.owner }

  before do
    sign_in(user)
    stub_licensed_features(licensed_features)
    visit edit_project_path(project)
  end

  context 'when `code_owner_approval_required` is available' do
    let(:licensed_features) { { code_owner_approval_required: true } }

    it 'allows the user to enforce code owner approval' do
      within('.require-code-owner-approval') do
        check('Require approval from code owners')
      end

      within('.merge-request-approval-settings-form') do
        click_on('Save changes')
      end

      expect(project.reload.merge_requests_require_code_owner_approval?).to be_truthy
    end
  end

  context 'when `code_owner_approval_required` is not available' do
    let(:licensed_features) { { code_owner_approval_required: false } }

    it 'does not allow the user to require code owner approval' do
      expect(page).not_to have_content('Require approval from code owners')
    end
  end
end
