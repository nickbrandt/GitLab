# frozen_string_literal: true

require 'spec_helper'

describe 'Trial Capture Lead', :js do
  include Select2Helper
  let(:user) { create(:user) }

  before do
    stub_feature_flags(invisible_captcha: false)
    stub_feature_flags(improved_trial_signup: true)
    allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    sign_in(user)
  end

  context 'when user' do
    before do
      visit new_trial_path

      wait_for_requests
    end

    context 'enters valid company information' do
      before do
        expect_any_instance_of(GitlabSubscriptions::CreateLeadService).to receive(:execute) do
          { success: true }
        end
      end

      it 'proceeds to the next step' do
        fill_in 'company_name', with: 'GitLab'
        select2 '1-99', from: '#company_size'
        fill_in 'phone_number', with: '+1234567890'
        fill_in 'number_of_users', with: '1'
        select2 'US', from: '#country_select'

        click_button 'Continue'

        expect(page).not_to have_css('flash-container')
        expect(current_path).to eq(select_trials_path)
      end
    end

    context 'enters invalid company information' do
      before do
        fill_in 'company_name', with: 'GitLab'
        select2 '1-99', from: '#company_size'
        # to trigger validation error
        # skip filling phone number
        # fill_in 'phone_number', with: '+1234567890'
        fill_in 'number_of_users', with: '1'
        select2 'US', from: '#country_select'

        click_button 'Continue'
      end

      it 'shows validation error' do
        message = page.find('#phone_number').native.attribute('validationMessage')

        expect(message).to eq('Please fill out this field.')
      end

      it 'does not proceeds to the next step' do
        expect(current_path).to eq(new_trial_path)
      end
    end
  end
end
