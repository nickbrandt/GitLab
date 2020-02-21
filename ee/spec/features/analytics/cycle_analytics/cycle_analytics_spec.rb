# frozen_string_literal: true
require 'spec_helper'

describe 'Group Value Stream Analytics', :js do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, name: "CA-test-group") }
  let!(:group2) { create(:group, name: "CA-bad-test-group") }
  let!(:project) { create(:project, :repository, namespace: group, group: group, name: "Cool fun project") }
  let!(:label) { create(:group_label, group: group) }
  let!(:label2) { create(:group_label, group: group) }
  let!(:label3) { create(:group_label, group: group2) }

  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  stage_nav_selector = '.stage-nav'

  3.times do |i|
    let!("issue_#{i}".to_sym) { create(:issue, title: "New Issue #{i}", project: project, created_at: 2.days.ago) }
  end

  shared_examples 'empty state' do
    it 'displays an empty state before a group is selected' do
      element = page.find('.row.empty-state')

      expect(element).to have_content(_("Value Stream Analytics can help you determine your team’s velocity"))
      expect(element.find('.svg-content img')['src']).to have_content('illustrations/analytics/cycle-analytics-empty-chart')
    end
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    # chart returns an error since theres no data
    stub_feature_flags(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG => false)

    group.add_owner(user)
    project.add_maintainer(user)

    sign_in(user)

    visit analytics_cycle_analytics_path
  end

  it_behaves_like "empty state"

  context 'deep linked url parameters' do
    group_dropdown = '.js-groups-dropdown-filter'
    projects_dropdown = '.js-projects-dropdown-filter'

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      group.add_owner(user)

      sign_in(user)
    end

    shared_examples "group dropdown set" do
      it "has the group dropdown prepopulated" do
        element = page.find(group_dropdown)

        expect(element).to have_content group.name
      end
    end

    context 'without valid query parameters set' do
      context 'with no group_id set' do
        before do
          visit analytics_cycle_analytics_path
        end

        it_behaves_like "empty state"
      end

      context 'with created_after date > created_before date' do
        before do
          visit "#{analytics_cycle_analytics_path}?created_after=2019-12-31&created_before=2019-11-01"
        end

        it_behaves_like "empty state"
      end

      context 'with fake parameters' do
        before do
          visit "#{analytics_cycle_analytics_path}?beans=not-cool"
        end

        it_behaves_like "empty state"
      end
    end

    context 'with valid query parameters set' do
      context 'with group_id set' do
        before do
          visit "#{analytics_cycle_analytics_path}?group_id=#{group.full_path}"
        end

        it_behaves_like "group dropdown set"
      end

      context 'with project_ids set' do
        before do
          visit "#{analytics_cycle_analytics_path}?group_id=#{group.full_path}&project_ids[]=#{project.id}"
        end

        it "has the projects dropdown prepopulated" do
          element = page.find(projects_dropdown)

          expect(element).to have_content project.name
        end

        it_behaves_like "group dropdown set"
      end

      context 'with created_before and created_after set' do
        date_range = '.js-daterange-picker'

        before do
          visit "#{analytics_cycle_analytics_path}?group_id=#{group.full_path}&created_before=2019-12-31&created_after=2019-11-01"
        end

        it "has the date range prepopulated" do
          element = page.find(date_range)

          expect(element.find('.js-daterange-picker-from input').value).to eq "2019-11-01"
          expect(element.find('.js-daterange-picker-to input').value).to eq "2019-12-31"
        end

        it_behaves_like "group dropdown set"
      end
    end
  end

  context 'displays correct fields after group selection' do
    before do
      select_group
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

  def wait_for_stages_to_load
    expect(page).to have_selector '.js-stage-table'
  end

  # TODO: Followup should have tests for stub_licensed_features(cycle_analytics_for_groups: false)
  def select_group
    dropdown = page.find('.dropdown-groups')
    dropdown.click
    dropdown.find('a').click

    wait_for_stages_to_load
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
      'Value Stream Analytics can help you determine your team’s velocity',
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
        expect(page).to have_selector(stage_nav_selector, visible: true)
      end

      it 'displays the default list of stages' do
        stage_nav = page.find(stage_nav_selector)

        %w[Issue Plan Code Test Review Staging Total].each do |item|
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
      { title: "Plan", description: "Time before an issue starts implementation", events_count: 0, median: "Not enough data" },
      { title: "Code", description: "Time until first merge request", events_count: 0, median: "Not enough data" },
      { title: "Test", description: "Total test time for all commits/merges", events_count: 0, median: "Not enough data" },
      { title: "Review", description: "Time between merge request creation and merge/close", events_count: 0, median: "Not enough data" },
      { title: "Staging", description: "From merge request merge until deploy to production", events_count: 0, median: "Not enough data" },
      { title: "Total", description: "From issue creation until deploy to production", events_count: 1, median: "5 days" }
    ]

    it 'each stage will have median values', :sidekiq_might_not_need_inline do
      stages = page.all(".stage-nav .stage-median").collect(&:text)

      stages.each_with_index do |median, index|
        expect(median).to eq(dummy_stages[index][:median])
      end
    end

    it 'each stage will display the events description when selected', :sidekiq_might_not_need_inline do
      dummy_stages.each do |stage|
        select_stage(stage[:title])

        if stage[:events_count] == 0
          expect(page).not_to have_selector('.stage-events .events-description')
        else
          expect(page.find('.stage-events .events-description').text).to have_text(stage[:description])
        end
      end
    end

    it 'each stage with events will display the stage events list when selected', :sidekiq_might_not_need_inline do
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

  describe 'Tasks by type chart', :js do
    context 'enabled' do
      before do
        stub_licensed_features(cycle_analytics_for_groups: true, type_of_work_analytics: true)
        stub_feature_flags(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG => true)

        sign_in(user)
      end

      context 'with data available' do
        before do
          3.times do |i|
            create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [label])
            create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [label2])
          end

          visit analytics_cycle_analytics_path
          select_group
        end

        it 'displays the chart' do
          expect(page).to have_text('Type of work')

          expect(page).to have_text('Tasks by type')
        end

        it 'has 2 labels selected' do
          expect(page).to have_text('Showing Issues and 2 labels')
        end

        it 'has chart filters' do
          expect(page).to have_css('.js-tasks-by-type-chart-filters')
        end
      end

      context 'no data available' do
        before do
          visit analytics_cycle_analytics_path

          select_group
        end

        it 'shows the no data available message' do
          expect(page).to have_text('Type of work')

          expect(page).to have_text('There is no data available. Please change your selection.')
        end
      end
    end

    context 'not enabled' do
      before do
        stub_feature_flags(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG => false)
        visit analytics_cycle_analytics_path

        select_group
      end

      it 'will not display the tasks by type chart' do
        expect(page).not_to have_selector('.js-tasks-by-type-chart')

        expect(page).not_to have_text('Tasks by type')
      end
    end
  end

  describe 'Customizable cycle analytics', :js do
    custom_stage_name = "Cool beans"
    custom_stage_with_labels_name = "Cool beans - now with labels"
    start_event_identifier = :merge_request_created
    end_event_identifier = :merge_request_merged
    start_label_event = :issue_label_added
    stop_label_event = :issue_label_removed

    let(:add_stage_button) { '.js-add-stage-button' }
    let(:params) { { name: custom_stage_name, start_event_identifier: start_event_identifier, end_event_identifier: end_event_identifier } }
    let(:first_default_stage) { page.find('.stage-nav-item-cell', text: "Issue").ancestor(".stage-nav-item") }
    let(:first_custom_stage) { page.find('.stage-nav-item-cell', text: custom_stage_name).ancestor(".stage-nav-item") }

    def create_custom_stage
      Analytics::CycleAnalytics::Stages::CreateService.new(parent: group, params: params, current_user: user).execute
    end

    def toggle_more_options(stage)
      stage.hover

      stage.find(".more-actions-toggle").click
    end

    def select_dropdown_option(name, elem = "option", index = 1)
      page.find("select[name='#{name}']").all(elem)[index].select_option
    end

    def select_dropdown_option_by_value(name, value, elem = "option")
      page.find("select[name='#{name}']").find("#{elem}[value=#{value}]").select_option
    end

    def select_dropdown_label(field, index = 2)
      page.find("[name=#{field}] .dropdown-toggle").click
      page.find("[name=#{field}] .dropdown-menu").all('.dropdown-item')[index].click
    end

    context 'enabled' do
      before do
        select_group
      end

      context 'Add a stage button' do
        it 'is visible' do
          expect(page).to have_selector(add_stage_button, visible: true)
          expect(page).to have_text('Add a stage')
        end

        it 'becomes active when clicked' do
          expect(page).not_to have_selector("#{add_stage_button}.active")

          find(add_stage_button).click

          expect(page).to have_selector("#{add_stage_button}.active")
        end

        it 'displays the custom stage form when clicked' do
          expect(page).not_to have_text('New stage')

          page.find(add_stage_button).click

          expect(page).to have_text('New stage')
        end
      end

      context 'Custom stage form' do
        let(:show_form_add_stage_button) { '.js-add-stage-button' }

        before do
          select_group

          page.find(show_form_add_stage_button).click
          wait_for_requests
        end

        context 'with empty fields' do
          it 'submit button is disabled by default' do
            expect(page).to have_button('Add stage', disabled: true)
          end
        end

        shared_examples 'submits the form successfully' do |stage_name|
          it 'submit button is enabled' do
            expect(page).to have_button('Add stage', disabled: false)
          end

          it 'submit button is disabled if the start event changes' do
            select_dropdown_option 'custom-stage-start-event', 'option', 2

            expect(page).to have_button('Add stage', disabled: true)
          end

          it 'the custom stage is saved' do
            click_button 'Add stage'

            expect(page).to have_selector('.stage-nav-item', text: stage_name)
          end

          it 'a confirmation message is displayed' do
            fill_in 'custom-stage-name', with: stage_name
            click_button 'Add stage'

            expect(page.find('.flash-notice')).to have_text("Your custom stage '#{stage_name}' was created")
          end

          it 'with a default name' do
            fill_in 'custom-stage-name', with: 'issue'
            click_button 'Add stage'

            expect(page).to have_button('Add stage', disabled: true)
          end
        end

        context 'with all required fields set' do
          before do
            fill_in 'custom-stage-name', with: custom_stage_name
            select_dropdown_option 'custom-stage-start-event'
            select_dropdown_option 'custom-stage-stop-event'
          end

          it 'does not have label dropdowns' do
            expect(page).not_to have_content('Start event label')
            expect(page).not_to have_content('Stop event label')
          end

          it_behaves_like 'submits the form successfully', custom_stage_name
        end

        context 'with label based stages selected' do
          before do
            fill_in 'custom-stage-name', with: custom_stage_with_labels_name
            select_dropdown_option_by_value 'custom-stage-start-event', start_label_event
            select_dropdown_option_by_value 'custom-stage-stop-event', stop_label_event
          end

          it 'has label dropdowns' do
            expect(page).to have_content('Start event label')
            expect(page).to have_content('Stop event label')
          end

          it 'submit button is disabled' do
            expect(page).to have_button('Add stage', disabled: true)
          end

          it 'does not contain labels from outside the group' do
            field = 'custom-stage-start-event-label'
            page.find("[name=#{field}] .dropdown-toggle").click

            menu = page.find("[name=#{field}] .dropdown-menu")

            expect(menu).not_to have_content(label3.name)
            expect(menu).to have_content(label.name)
            expect(menu).to have_content(label2.name)
          end

          context 'with all required fields set' do
            before do
              select_dropdown_label 'custom-stage-start-event-label', 1
              select_dropdown_label 'custom-stage-stop-event-label', 2
            end

            it_behaves_like 'submits the form successfully', custom_stage_with_labels_name
          end
        end
      end

      context 'Edit stage form' do
        stage_form_class = '.custom-stage-form'
        stage_save_button = '.js-save-stage'
        name_field = "custom-stage-name"
        start_event_field = "custom-stage-start-event"
        end_event_field = "custom-stage-stop-event"
        updated_custom_stage_name = 'Extra uber cool stage'

        def select_edit_stage
          toggle_more_options(first_custom_stage)
          click_button "Edit stage"
        end

        before do
          create_custom_stage
          select_group

          expect(page).to have_text custom_stage_name
        end

        context 'with no changes to the data' do
          before do
            select_edit_stage
          end

          it 'displays the editing stage form' do
            expect(page.find(stage_form_class)).to have_text 'Editing stage'
          end

          it 'prepoulates the stage data' do
            expect(page.find_field(name_field).value).to eq custom_stage_name
            expect(page.find_field(start_event_field).value).to eq start_event_identifier.to_s
            expect(page.find_field(end_event_field).value).to eq end_event_identifier.to_s
          end

          it 'disables the submit form button' do
            expect(page.find(stage_save_button)[:disabled]).to eq "true"
          end
        end

        context 'with changes' do
          before do
            select_edit_stage
          end

          it 'enables the submit button' do
            fill_in name_field, with: updated_custom_stage_name

            expect(page.find(stage_save_button)[:disabled]).to eq nil
          end

          it 'will persist updates to the stage' do
            fill_in name_field, with: updated_custom_stage_name
            page.find(stage_save_button).click

            expect(page.find('.flash-notice')).to have_text 'Stage data updated'
            expect(page.find(stage_nav_selector)).not_to have_text custom_stage_name
            expect(page.find(stage_nav_selector)).to have_text updated_custom_stage_name
          end

          it 'disables the submit form button if incomplete' do
            fill_in name_field, with: ""

            expect(page.find(stage_save_button)[:disabled]).to eq "true"
          end

          it 'with a default name' do
            fill_in name_field, with: 'issue'
            page.find(stage_save_button).click

            expect(page.find(stage_form_class)).to have_text("Stage name already exists")
          end
        end
      end

      context 'Stage table' do
        context 'default stages' do
          let(:nav) { page.find(stage_nav_selector) }

          def open_recover_stage_dropdown
            find(add_stage_button).click

            expect(page).to have_content('New stage')
            expect(page).to have_content('Recover hidden stage')

            click_button "Recover hidden stage"

            within(:css, '.js-recover-hidden-stage-dropdown') do
              expect(find(".dropdown-menu")).to have_content('Default stages')
            end
          end

          def active_stages
            page.all(".stage-nav .stage-name").collect(&:text)
          end

          before do
            select_group

            toggle_more_options(first_default_stage)
          end

          it 'can be hidden' do
            expect(first_default_stage.find('.more-actions-dropdown')).to have_text "Hide stage"
          end

          it 'can not be edited' do
            expect(first_default_stage.find('.more-actions-dropdown')).not_to have_text "Edit stage"
          end

          it 'can not be removed' do
            expect(first_default_stage.find('.more-actions-dropdown')).not_to have_text "Remove stage"
          end

          context 'hidden' do
            before do
              click_button "Hide stage"

              # wait for the stage list to laod
              expect(nav).to have_content("Plan")
            end

            it 'will not appear in the stage table' do
              expect(active_stages).not_to include("Issue")
            end

            it 'can be recovered' do
              open_recover_stage_dropdown

              expect(page.find('.js-recover-hidden-stage-dropdown')).to have_text('Issue')
            end
          end

          context 'recovered' do
            before do
              click_button "Hide stage"

              # wait for the stage list to laod
              expect(nav).to have_content("Plan")
            end

            it 'will appear in the stage table' do
              open_recover_stage_dropdown

              click_button("Issue")
              # wait for the stage list to laod
              expect(nav).to have_content("Plan")

              expect(page.find('.flash-notice')).to have_content 'Stage data updated'
              expect(active_stages).to include("Issue")
            end
          end
        end

        context 'custom stages' do
          before do
            create_custom_stage
            select_group

            expect(page).to have_text custom_stage_name

            toggle_more_options(first_custom_stage)
          end

          it 'can not be hidden' do
            expect(first_custom_stage.find('.more-actions-dropdown')).not_to have_text "Hide stage"
          end

          it 'can be edited' do
            expect(first_custom_stage.find('.more-actions-dropdown')).to have_text "Edit stage"
          end

          it 'can be removed' do
            expect(first_custom_stage.find('.more-actions-dropdown')).to have_text "Remove stage"
          end

          it 'will not appear in the stage table after being removed' do
            nav = page.find(stage_nav_selector)
            expect(nav).to have_text(custom_stage_name)

            click_button "Remove stage"

            expect(page.find('.flash-notice')).to have_text 'Stage removed'
            expect(nav).not_to have_text(custom_stage_name)
          end
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
