# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Value stream analytics charts', :js do
  include CycleAnalyticsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'CA-test-group') }
  let_it_be(:group2) { create(:group, name: 'CA-bad-test-group') }
  let_it_be(:project) { create(:project, :repository, namespace: group, group: group, name: 'Cool fun project') }
  let_it_be(:group_label1) { create(:group_label, group: group) }
  let_it_be(:group_label2) { create(:group_label, group: group) }
  let_it_be(:label) { create(:group_label, group: group2) }

  3.times do |i|
    let_it_be("issue_#{i}".to_sym) { create(:issue, title: "New Issue #{i}", project: project, created_at: 2.days.ago) }
  end

  def toggle_more_options(stage)
    stage.hover

    stage.find('[data-testid="more-actions-toggle"]').click
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_owner(user)

    sign_in(user)
  end

  context 'Duration chart' do
    duration_stage_selector = '.js-dropdown-stages'
    stage_nav_selector = '.stage-nav'
    stage_table_selector = '.js-stage-table'

    let(:duration_chart_dropdown) { page.find(duration_stage_selector) }
    let(:first_default_stage) { page.find('.stage-nav-item-cell', text: 'Issue').ancestor('.stage-nav-item') }
    let(:nav) { page.find(stage_nav_selector) }

    let_it_be(:translated_default_stage_names) do
      Gitlab::Analytics::CycleAnalytics::DefaultStages.names.map do |name|
        stage = Analytics::CycleAnalytics::GroupStage.new(name: name)
        Analytics::CycleAnalytics::StagePresenter.new(stage).title
      end.freeze
    end

    def duration_chart_stages
      duration_chart_dropdown.all('.dropdown-item').collect(&:text)
    end

    def toggle_duration_chart_dropdown
      duration_chart_dropdown.click
    end

    before do
      stub_feature_flags(value_stream_analytics_path_navigation: false)
      select_group(group, stage_table_selector)
    end

    it 'has all the default stages' do
      toggle_duration_chart_dropdown

      expect(duration_chart_stages).to eq(translated_default_stage_names)
    end

    context 'hidden stage' do
      before do
        toggle_more_options(first_default_stage)

        click_button(_('Hide stage'))

        # wait for the stage list to laod
        expect(nav).to have_content(s_('CycleAnalyticsStage|Plan'))
      end

      it 'will not appear in the duration chart dropdown' do
        toggle_duration_chart_dropdown

        expect(duration_chart_stages).not_to include(s_('CycleAnalyticsStage|Issue'))
      end
    end
  end

  describe 'Tasks by type chart', :js do
    filters_selector = '.js-tasks-by-type-chart-filters'

    before do
      stub_licensed_features(cycle_analytics_for_groups: true, type_of_work_analytics: true)

      group.add_owner(user)
      project.add_maintainer(user)

      sign_in(user)
    end

    context 'enabled' do
      context 'with data available' do
        before do
          mr_issue = create(:labeled_issue, created_at: 5.days.ago, project: create(:project, group: group), labels: [group_label2])
          create(:merge_request, iid: mr_issue.id, created_at: 3.days.ago, source_project: project, labels: [group_label1, group_label2])

          3.times do |i|
            create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [group_label1])
            create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [group_label2])
          end

          select_group(group)
        end

        it 'displays the chart' do
          expect(page).to have_text(s_('CycleAnalytics|Type of work'))

          expect(page).to have_text(s_('CycleAnalytics|Tasks by type'))
        end

        it 'has 2 labels selected' do
          expect(page).to have_text('Showing issues and 2 labels')
        end

        it 'has chart filters' do
          expect(page).to have_css(filters_selector)
        end

        it 'can update the filters' do
          page.within filters_selector do
            find('.dropdown-toggle').click
            first_selected_label = all('[data-testid="type-of-work-filters-label"] .dropdown-item.active').first
            first_selected_label.click
          end

          expect(page).to have_text('Showing issues and 1 label')

          page.within filters_selector do
            find('.dropdown-toggle').click
            find('[data-testid="type-of-work-filters-subject"] label', text: 'merge requests').click
          end

          expect(page).to have_text('Showing merge requests and 1 label')
        end
      end

      context 'no data available' do
        before do
          select_group(group)
        end

        it 'shows the no data available message' do
          expect(page).to have_text(s_('CycleAnalytics|Type of work'))

          expect(page).to have_text(_('There is no data available. Please change your selection.'))
        end
      end
    end
  end
end
