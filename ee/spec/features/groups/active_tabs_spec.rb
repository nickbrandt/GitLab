# frozen_string_literal: true

require 'spec_helper'

describe 'Group active tab' do
  let(:user) { create :user }
  let(:group) { create(:group) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  def click_tab(title)
    page.within '.sidebar-top-level-items > .active' do
      click_link(title)
    end
  end

  context 'when `analytics_pages_under_group_analytics_sidebar` feature flag is off' do
    before do
      stub_feature_flags(analytics_pages_under_group_analytics_sidebar: { enabled: false, thing: group })
    end

    context 'on group Insights' do
      before do
        stub_licensed_features(insights: true)

        visit group_insights_path(group)
      end

      it_behaves_like 'page has active tab', _('Group overview')
      it_behaves_like 'page has active sub tab', _('Insights')
    end

    context 'on group Issue Analytics' do
      before do
        stub_licensed_features(issues_analytics: true)

        visit group_issues_analytics_path(group)
      end

      it_behaves_like 'page has active tab', _('Issues')
      it_behaves_like 'page has active sub tab', _('Analytics')
    end

    context 'on group Contribution Analytics' do
      before do
        visit group_contribution_analytics_path(group)
      end

      it_behaves_like 'page has active tab', _('Group overview')
      it_behaves_like 'page has active sub tab', _('Contribution Analytics')
    end
  end

  context 'when `analytics_pages_under_group_analytics_sidebar` feature flag is on' do
    before do
      stub_feature_flags(analytics_pages_under_group_analytics_sidebar: { enabled: true, thing: group })
    end

    context 'on group Insights' do
      before do
        stub_licensed_features(insights: true)

        visit group_insights_path(group)
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Insights')
    end

    context 'on group Issue Analytics' do
      before do
        stub_licensed_features(issues_analytics: true)

        visit group_issues_analytics_path(group)
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Issues Analytics')
    end

    context 'on group Contribution Analytics' do
      before do
        visit group_contribution_analytics_path(group)
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Contribution Analytics')
    end

    context 'on group Productivity Analytics' do
      before do
        stub_licensed_features(productivity_analytics: true)

        visit group_analytics_productivity_analytics_path(group)
      end

      it_behaves_like 'page has active tab', _('Analytics')
      it_behaves_like 'page has active sub tab', _('Productivity Analytics')
    end
  end
end
