# frozen_string_literal: true
require 'spec_helper'

describe 'Group Cycle Analytics', :js do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, name: "CA-test-group") }
  let!(:project) { create(:project, :repository, namespace: group, group: group, name: "Cool fun project") }

  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  3.times do |i|
    let!("issue_#{i}".to_sym) { create(:issue, title: "New Issue #{i}", project: project, created_at: 2.days.ago) }
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
    group.add_owner(user)
    project.add_maintainer(user)

    sign_in(user)

    visit analytics_cycle_analytics_path
  end

  it 'displays an empty state before a group is selected' do
    element = page.find('.row.empty-state')

    expect(element).to have_content("Cycle Analytics can help you determine your team’s velocity")
    expect(element.find('.svg-content img')['src']).to have_content('illustrations/analytics/cycle-analytics-empty-chart')
  end

  context 'displays correct fields after group selection' do
    before do
      dropdown = page.find('.dropdown-groups')
      dropdown.click
      dropdown.find('a').click
    end

    it 'hides the empty state' do
      expect(page).to have_selector('.row.empty-state', visible: false)
    end

    it 'shows the projects filter' do
      expect(page).to have_selector('.dropdown-projects', visible: true)
    end

    it 'shows the date filter' do
      expect(page).to have_selector('.js-daterange-picker', visible: true)
    end
  end

  # TODO: Followup should have tests for stub_licensed_features(cycle_analytics_for_groups: false)
  def select_group
    dropdown = page.find('.dropdown-groups')
    dropdown.click
    dropdown.find('a').click
  end

  def select_project
    select_group

    dropdown = page.find('.dropdown-projects')
    dropdown.click
    dropdown.find('a').click
    dropdown.click
  end

  it 'displays empty text' do
    [
      'Cycle Analytics can help you determine your team’s velocity',
      'Start by choosing a group to see how your team is spending time. You can then drill down to the project level.'
    ].each do |content|
      expect(page).to have_content(content)
    end
  end

  context 'with a group selected' do
    before do
      select_group
    end

    context 'summary table', :js do
      it 'will display recent activity' do
        page.within(find('.js-summary-table')) do
          expect(page).to have_selector('.card-header')
          expect(page).to have_content('Recent Activity')
        end
      end

      it 'displays the number of issues' do
        expect(page).to have_content('New Issues')

        issue_count = find(".card .header", match: :first)
        expect(issue_count).to have_content('3')
      end

      it 'displays the number of deploys' do
        expect(page).to have_content('Deploys')

        deploys_count = page.all(".card .header").last
        expect(deploys_count).to have_content('-')
      end
    end

    context 'stage panel' do
      it 'displays the stage table headers' do
        expect(page).to have_selector('.stage-header', visible: true)
        expect(page).to have_selector('.median-header', visible: true)
        expect(page).to have_selector('.event-header', visible: true)
        expect(page).to have_selector('.total-time-header', visible: true)
      end
    end

    context 'stage nav' do
      it 'displays the list of stages' do
        expect(page).to have_selector('.stage-nav', visible: true)
      end

      it 'displays the default list of stages' do
        stage_nav = page.find('.stage-nav')

        %w[Issue Plan Code Test Review Staging Production].each do |item|
          expect(stage_nav).to have_content(item)
        end
      end
    end
  end

  def select_stage(name)
    page.find('.stage-nav .stage-nav-item .stage-name', text: name, match: :prefer_exact).click

    wait_for_requests
  end

  def create_merge_request(id, extra_params = {})
    params = {
      id: id,
      target_branch: 'master',
      source_project: project2,
      source_branch: "feature-branch-#{id}",
      title: "mr name#{id}",
      created_at: 2.days.ago
    }.merge(extra_params)

    create(:merge_request, params)
  end

  context 'with lots of data', :js do
    let!(:issue) { create(:issue, project: project, created_at: 5.days.ago) }

    before do
      create_cycle(user, project, issue, mr, milestone, pipeline)

      deploy_master(user, project, environment: 'staging')
      deploy_master(user, project)

      select_group
    end

    dummy_stages = [
      { title: "Issue", description: "Time before an issue gets scheduled", events_count: 1, median: "5 days" },
      { title: "Plan", description: "Time before an issue starts implementation", events_count: 1, median: "Not enough data" },
      { title: "Code", description: "Time until first merge request", events_count: 1, median: "less than a minute" },
      { title: "Test", description: "Total test time for all commits/merges", events_count: 1, median: "Not enough data" },
      { title: "Review", description: "Time between merge request creation and merge/close", events_count: 1, median: "less than a minute" },
      { title: "Staging", description: "From merge request merge until deploy to production", events_count: 1, median: "less than a minute" },
      { title: "Production", description: "From issue creation until deploy to production", events_count: 1, median: "5 days" }
    ]

    it 'each stage will have median values' do
      stages = page.all(".stage-nav .stage-median").collect(&:text)

      stages.each_with_index do |median, index|
        expect(median).to eq(dummy_stages[index][:median])
      end
    end

    it 'each stage will display the events description when selected' do
      dummy_stages.each do |stage|
        select_stage(stage[:title])

        expect(page.find('.stage-events .events-description').text).to have_text(stage[:description])
      end
    end

    it 'each stage with events will display the stage events list when selected' do
      dummy_stages.each do |stage|
        select_stage(stage[:title])

        if stage[:events_count] == 0
          expect(page).not_to have_selector('.stage-events .stage-event-item')
        else
          expect(page).to have_selector('.stage-events .stage-event-list')
          expect(page.all('.stage-events .stage-event-item').length).to eq(stage[:events_count])
        end
      end
    end

    it 'each stage will be selectable' do
      dummy_stages.each do |stage|
        select_stage(stage[:title])

        expect(page.find('.stage-nav .active .stage-name').text).to eq(stage[:title])
      end
    end
  end

  describe 'Customizable cycle analytics', :js do
    let(:button_class) { '.js-add-stage-button' }

    context 'enabled' do
      before do
        dropdown = page.find('.dropdown-groups')
        dropdown.click
        dropdown.find('a').click

        # Make capybara wait until all the .stage-nav-item elements are rendered
        # We should have NUMBER_OF_STAGES + 1 (button)
        expect(page).to have_selector(
          '.stage-nav-item',
          count: Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size + 1
        )
      end

      context 'Add a stage button' do
        it 'is visible' do
          expect(page).to have_selector(button_class, visible: true)
          expect(page).to have_text('Add a stage')
        end

        it 'becomes active when clicked' do
          expect(page).not_to have_selector("#{button_class}.active")

          find(button_class).click

          expect(page).to have_selector("#{button_class}.active")
        end

        it 'displays the custom stage form when clicked' do
          expect(page).not_to have_text('New stage')

          page.find(button_class).click

          expect(page).to have_text('New stage')
        end
      end
    end

    context 'not enabled' do
      before do
        stub_feature_flags(customizable_cycle_analytics: false)

        dropdown = page.find('.dropdown-groups')
        dropdown.click
        dropdown.find('a').click
      end

      context 'Add a stage button' do
        it 'is not visible' do
          expect(page).to have_selector('.js-add-stage-button', visible: false)
        end
      end
    end
  end
end
