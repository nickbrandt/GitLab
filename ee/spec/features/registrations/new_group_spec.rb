# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New group screen', :js do
  let_it_be(:user) { create(:user) }

  before do
    gitlab_sign_in(user)
    stub_experiment_for_user(onboarding_issues: true)
    visit new_users_sign_up_group_path
  end

  subject { page }

  it 'shows the progress bar with the correct steps' do
    expect(subject).to have_content('Create your group')
    expect(subject).to have_content('1. Your profile 2. Your GitLab group 3. Your first project')
  end
end
