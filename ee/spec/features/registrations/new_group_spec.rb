# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New group screen', :js do
  let_it_be(:user) { create(:user) }

  before do
    gitlab_sign_in(user)
    stub_experiment_for_user(onboarding_issues: true)
    visit new_users_sign_up_group_path
  end

  it 'shows the progress bar with the correct steps' do
    expect(page).to have_content('Create your group')
    expect(page).to have_content('1. Your profile 2. Your GitLab group 3. Your first project')
  end

  it 'autofills the group path' do
    fill_in 'group_name', with: 'test'

    expect(page).to have_field('group_path', with: 'test')
  end
end
