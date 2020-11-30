# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User visits the profile preferences page' do
  include Select2Helper

  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_preferences_path)
  end

  it 'shows correct menu item' do
    expect(page).to have_active_navigation('Preferences')
  end

  describe 'User changes their syntax highlighting theme', :js do
    it 'creates a flash message' do
      choose 'user_color_scheme_id_5'

      wait_for_requests

      expect_preferences_saved_message
    end

    it 'updates their preference' do
      choose 'user_color_scheme_id_5'

      wait_for_requests
      refresh

      expect(page).to have_checked_field('user_color_scheme_id_5')
    end
  end

  def expect_preferences_saved_message
    page.within('.flash-container') do
      expect(page).to have_content('Preferences saved.')
    end
  end
end
