# frozen_string_literal: true
require 'spec_helper'

describe 'Group Cycle Analytics', :js do
  let!(:user) { create(:user) }
  let!(:group) { create(:group, name: "CA-test-group") }
  let!(:project) { create(:project, :repository, namespace: group, group: group, name: "Cool fun project") }

  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }

  stage_nav_selector = '.stage-nav'

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

  describe 'Customizable cycle analytics', :js do
    custom_stage_name = "Cool beans"
    start_event_identifier = :merge_request_created
    end_event_identifier = :merge_request_merged

    let(:button_class) { '.js-add-stage-button' }
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

    context 'enabled' do
      before do
        select_group
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

      context 'Custom stage form' do
        let(:show_form_button_class) { '.js-add-stage-button' }

        def select_dropdown_option(name, elem = "option", index = 1)
          page.find("select[name='#{name}']").all(elem)[index].select_option
        end

        before do
          select_group

          page.find(show_form_button_class).click
          wait_for_requests
        end

        context 'with empty fields' do
          it 'submit button is disabled by default' do
            expect(page).to have_button('Add stage', disabled: true)
          end
        end

        context 'with all required fields set' do
          before do
            fill_in 'custom-stage-name', with: custom_stage_name
            select_dropdown_option 'custom-stage-start-event'
            select_dropdown_option 'custom-stage-stop-event'
          end

          it 'submit button is enabled' do
            expect(page).to have_button('Add stage', disabled: false)
          end

          it 'submit button is disabled if the start event changes' do
            select_dropdown_option 'custom-stage-start-event', 'option', 2

            expect(page).to have_button('Add stage', disabled: true)
          end

          it 'an error message is displayed if the start event is changed' do
            select_dropdown_option 'custom-stage-start-event', 'option', 2

            expect(page).to have_text 'Start event changed, please select a valid stop event'
          end

          context 'submit button is clicked' do
            it 'the custom stage is saved' do
              click_button 'Add stage'

              expect(page).to have_selector('.stage-nav-item', text: custom_stage_name)
            end

            it 'a confirmation message is displayed' do
              name = 'cool beans number 2'
              fill_in 'custom-stage-name', with: name
              click_button 'Add stage'

              expect(page.find('.flash-notice')).to have_text("Your custom stage '#{name}' was created")
            end

            it 'with a default name' do
              name = 'issue'
              fill_in 'custom-stage-name', with: name
              click_button 'Add stage'

              expect(page.find('.flash-alert')).to have_text("'#{name}' stage already exists")
            end
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
            name = 'issue'
            fill_in name_field, with: name
            page.find(stage_save_button).click

            expect(page.find('.flash-alert')).to have_text("'#{name}' stage already exists")
          end
        end
      end

      context 'Stage table' do
        context 'default stages' do
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

          it 'will not appear in the stage table after being hidden' do
            nav = page.find(stage_nav_selector)
            expect(nav).to have_text("Issue")

            click_button "Hide stage"

            expect(page.find('.flash-notice')).to have_text 'Stage data updated'
            expect(nav).not_to have_text("Issue")
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
