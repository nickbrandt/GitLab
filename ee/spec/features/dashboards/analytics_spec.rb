# frozen_string_literal: true

require 'spec_helper'

describe 'Showing analytics' do
  include AnalyticsHelpers

  before do
    sign_in user if user
  end

  # Using a path that is publicly accessible
  subject { visit explore_projects_path }

  context 'for regular users' do
    let(:user) { create(:user) }

    context 'with access to instance statistics or analytics features' do
      it 'shows the analytics link' do
        subject

        expect(page).to have_link('Analytics')
      end
    end

    context 'without access to instance statistics and analytics features' do
      before do
        disable_all_analytics_feature_flags
        stub_application_setting(instance_statistics_visibility_private: true)
      end

      it 'does not show the analytics link' do
        subject

        expect(page).not_to have_link('Analytics')
      end
    end
  end
end
