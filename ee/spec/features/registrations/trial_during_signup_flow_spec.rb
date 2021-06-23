# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees new onboarding flow', :js do
  include Select2Helper
  let_it_be(:user) { create(:user) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    sign_in(user)
    visit users_sign_up_welcome_path

    expect(page).to have_content('Welcome to GitLab')

    choose 'My company or team'
    click_on 'Continue'

    expect(page).to have_content('GitLab Ultimate trial (optional)')
  end

  it 'shows the expected behavior with no trial chosen', :aggregate_failures do
    fill_in 'group_name', with: 'test'

    click_on 'Create group'

    expect(page).not_to have_content('Congratulations, your free trial is activated.')
    expect(page).to have_content('Invite your teammates')
  end

  it 'shows the expected behavior with trial chosen' do
    fields = ['Company name', 'Number of employees', 'How many employees will use Gitlab?', 'Telephone number', 'Country']
    fill_in 'group_name', with: 'test'

    # fields initially invisible
    fields.each { |field| expect(page).not_to have_content(field) }

    # fields become visible with trial toggle
    click_button class: 'gl-toggle'

    fields.each { |field| expect(page).to have_content(field) }

    # fields are required
    click_on 'Create group'

    expect(page).to have_content('This field is required')

    # make fields invisible again
    click_button class: 'gl-toggle'

    fields.each { |field| expect(page).not_to have_content(field) }

    # make fields visible again
    click_button class: 'gl-toggle'

    fields.each { |field| expect(page).to have_content(field) }

    # submit the trial form
    fill_in 'company_name', with: 'GitLab'
    select2 '1-99', from: '#company_size'
    fill_in 'number_of_users', with: '1'
    fill_in 'phone_number', with: '+1234567890'
    select2 'US', from: '#country_select'

    expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
      expect(service).to receive(:execute).and_return(success: true)
    end
    expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
      expect(service).to receive(:execute).and_return({ success: true })
    end

    click_on 'Create group'

    expect(page).to have_content('Congratulations, your free trial is activated.')
    expect(page).to have_content('Invite your teammates')
  end
end
