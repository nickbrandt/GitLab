# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/profile' do
  let(:user) { create(:user) }

  before do
    allow(view).to receive(:session).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
    allow(view).to receive(:experiment_enabled?).and_return(false)
  end

  context 'when seach_settings_in_page feature flag is on' do
    before do
      stub_feature_flags(search_settings_in_page: true)
    end

    it 'displays the search settings entry point' do
      render
      expect(rendered).to include('js-search-settings-app')
      have_received(:enable_search_settings)
                            .with({ locals: { container_class: 'gl-my-5' } })
    end
  end

  context 'when seach_settings_in_page feature flag is off' do
    before do
      stub_feature_flags(search_settings_in_page: false)
    end

    it 'does not display the search settings entry point' do
      render
      expect(rendered).not_to include('js-search-settings-app')
      have_not_received(:enable_search_settings)
    end
  end
end
