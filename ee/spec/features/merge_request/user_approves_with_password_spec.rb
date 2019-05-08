# frozen_string_literal: true

require 'rails_helper'

describe 'Merge request > User approves with password', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository, approvals_before_merge: 1, require_password_to_approve: true, merge_requests_author_approval: true) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it 'works, when user approves and enters correct password' do
    page.within('.js-mr-approvals') do
      approve_with_password '12345678'

      expect(page).not_to have_button('Approve')
      expect(page).to have_text('Approved by')
    end
  end

  it 'does not need password to unapprove' do
    approve_with_password '12345678'
    unapprove

    expect(page).to have_button('Approve')
    expect(page).not_to have_text('Approved by')
  end

  it 'shows error, when user approves and enters incorrect password' do
    page.within('.js-mr-approvals') do
      approve_with_password 'nottherightpassword'

      expect(page).to have_text('Approval password is invalid.')
      click_button 'Cancel'
      expect(page).not_to have_text('Approved by')
    end
  end
end

def approve_with_password(password)
  click_button('Approve')
  fill_in(type: 'password', with: password)
  click_button('Confirm')
  wait_for_requests
end

def unapprove
  click_button('Revoke approval')
  wait_for_requests
end
