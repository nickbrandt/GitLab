# frozen_string_literal: true

require 'spec_helper'

describe 'CodeReviewAnalytics Filtered Search', :js do
  include FilteredSearchHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    stub_licensed_features(code_review_analytics: true)

    project.add_reporter(user)
  end

  context 'when the "new search" feature is disabled' do
    before do
      stub_feature_flags(code_review_analytics_has_new_search: false)

      sign_in(user)

      visit project_analytics_code_reviews_path(project)
    end

    it 'renders the filtered search bar correctly' do
      page.within('.content-wrapper .content .issues-filters') do
        expect(page).to have_css('.filtered-search-box')
      end
    end

    it 'displays label and milestone in search hint' do
      filtered_search.click

      page.within('#js-dropdown-hint') do
        expect(page).to have_content('Label')
        expect(page).to have_content('Milestone')
      end
    end
  end

  context 'when the "new search" feature is enabled' do
    before do
      stub_feature_flags(code_review_analytics_has_new_search: true)

      sign_in(user)

      visit project_analytics_code_reviews_path(project)
    end

    it 'does not render the filtered search bar' do
      page.within('.content-wrapper .content') do
        expect(page).not_to have_css('.issues-filters')
      end
    end
  end
end
