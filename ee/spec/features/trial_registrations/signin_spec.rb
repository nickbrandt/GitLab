# frozen_string_literal: true

require 'spec_helper'

describe 'Trial Sign In' do
  let(:user) { create(:user) }

  describe 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    end

    it 'logs the user in' do
      visit(new_trial_registration_path)

      within('div#login-pane') do
        fill_in 'user_login', with: user.email
        fill_in 'user_password', with: '12345678'

        click_button 'Continue'
      end

      expect(current_path).to eq(new_trial_path)
    end
  end

  describe 'not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false).at_least(:once)
    end

    it 'returns 404' do
      visit(new_trial_registration_path)

      expect(status_code).to eq(404)
    end
  end
end
