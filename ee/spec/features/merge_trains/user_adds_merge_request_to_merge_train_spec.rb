# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User adds a merge request to a merge train', :js do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let!(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master')
  end

  let(:ci_yaml) do
    { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
  end

  before do
    stub_const('Gitlab::QueryLimiting::Transaction::THRESHOLD', 200)
    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    project.add_maintainer(user)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    merge_request.all_pipelines.first.succeed!
    merge_request.update_head_pipeline
    stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))

    sign_in(user)
  end

  it "shows 'Start merge train' button" do
    visit project_merge_request_path(project, merge_request)

    expect(page).to have_button('Start merge train')
  end

  context 'when merge_trains EEP license is not available' do
    before do
      stub_licensed_features(merge_trains: false)
    end

    it 'does not show Start merge train' do
      visit project_merge_request_path(project, merge_request)

      expect(page).not_to have_button('Start merge train')
    end
  end

  context "when user clicks 'Start merge train' button" do
    before do
      visit project_merge_request_path(project, merge_request)
      click_button 'Start merge train'
      wait_for_requests
    end

    it 'informs merge request that auto merge is enabled' do
      within('.mr-widget-section') do
        expect(page).to have_content("Added to the merge train by #{user.name}")
        expect(page).to have_content('The source branch will not be deleted')
        expect(page).to have_link('Remove from merge train')
        expect(page).to have_link('Delete source branch')
      end
    end

    context 'when pipeline for merge train succeeds', :sidekiq_might_not_need_inline do
      let_it_be(:runner) { create(:ci_runner) }

      before do
        visit project_merge_request_path(project, merge_request)
        merge_request.merge_train.pipeline.builds.map(&:success!)
      end

      it 'displays pipeline control' do
        expect(page).to have_selector('[data-testid="mini-pipeline-graph-dropdown"]')
      end

      it 'does not allow retry for merge train pipeline' do
        find('[data-testid="mini-pipeline-graph-dropdown"] .dropdown-toggle').click
        page.within '.ci-job-component' do
          expect(page).to have_selector('.ci-status-icon')
          expect(page).not_to have_selector('.retry')
        end
      end
    end

    context "when user clicks 'Remove from merge train' button" do
      before do
        click_link 'Remove from merge train'
      end

      it 'cancels automatic merge' do
        within('.mr-widget-section') do
          expect(page).not_to have_content("Added to the merge train by #{user.name}")
          expect(page).to have_button('Start merge train')
        end
      end
    end

    context "when user clicks 'Delete source branch" do
      before do
        click_link 'Delete source branch'
      end

      it 'updates the merge option' do
        within('.mr-widget-section') do
          expect(page).to have_content('The source branch will be deleted')
        end
      end
    end
  end

  context 'when the merge request is not the first queue on the train' do
    before do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'signed-commits',
        target_project: project, target_branch: 'master')
    end

    it "shows 'Add to merge train' button" do
      visit project_merge_request_path(project, merge_request)

      expect(page).to have_button('Add to merge train')
    end
  end
end
