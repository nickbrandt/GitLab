# frozen_string_literal: true
require 'spec_helper'

describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  include JavaScriptFixturesHelpers

  let(:group) { create(:group)}
  let(:project) { create(:project, :repository, namespace: group) }
  let(:user) { create(:user, :admin) }
  # let(:issue) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  # let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }

  let(:issue) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:issue_1) { create(:issue, project: project, created_at: 5.days.ago) }
  let(:issue_2) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:issue_3) { create(:issue, project: project, created_at: 3.days.ago) }

  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:mr_1) { create(:merge_request, source_project: project, allow_broken: true, created_at: 20.days.ago) }
  let(:mr_2) { create(:merge_request, source_project: project, allow_broken: true, created_at: 19.days.ago) }
  let(:mr_3) { create(:merge_request, source_project: project, allow_broken: true, created_at: 18.days.ago) }

  let(:pipeline_1) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr_1.source_branch, sha: mr_1.source_branch_sha, head_pipeline_of: mr_1) }
  let(:pipeline_2) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr_2.source_branch, sha: mr_2.source_branch_sha, head_pipeline_of: mr_2) }
  let(:pipeline_3) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr_3.source_branch, sha: mr_3.source_branch_sha, head_pipeline_of: mr_3) }

  let(:build_1) { create(:ci_build, :success, pipeline: pipeline_1, author: user) }
  let(:build_2) { create(:ci_build, :success, pipeline: pipeline_2, author: user) }
  let(:build_3) { create(:ci_build, :success, pipeline: pipeline_3, author: user) }

  def prepare_cycle_analytics_data
    group.add_maintainer(user)
    project.add_maintainer(user)

    create_cycle(user, project, issue_1, mr_1, milestone, pipeline_1)
    create_cycle(user, project, issue_2, mr_2, milestone, pipeline_2)

    create_commit_referencing_issue(issue_1)
    create_commit_referencing_issue(issue_2)

    create_merge_request_closing_issue(user, project, issue_1)
    create_merge_request_closing_issue(user, project, issue_2)
    merge_merge_requests_closing_issue(user, project, issue_3)
  end

  def create_deployment
    deploy_master(user, project, environment: 'staging')
    deploy_master(user, project)
  end

  def update_metrics
    issue_1.metrics.update(first_added_to_board_at: 3.days.ago, first_mentioned_in_commit_at: 2.days.ago)
    issue_2.metrics.update(first_added_to_board_at: 2.days.ago, first_mentioned_in_commit_at: 1.day.ago)

    mr_1.metrics.update!({
      merged_at: 5.days.ago,
      first_deployed_to_production_at: 1.day.ago,
      latest_build_started_at: 5.days.ago,
      latest_build_finished_at: 1.day.ago,
      pipeline: build_1.pipeline
    })

    mr_2.metrics.update!({
      merged_at: 10.days.ago,
      first_deployed_to_production_at: 5.days.ago,
      latest_build_started_at: 9.days.ago,
      latest_build_finished_at: 7.days.ago,
      pipeline: build_2.pipeline
    })
  end

  def additional_cycle_analytics_metrics
    create(:cycle_analytics_group_stage, parent: group)

    update_metrics

    create_cycle(user, project, issue_1, mr_1, milestone, pipeline_1)
    create_cycle(user, project, issue_2, mr_2, milestone, pipeline_2)
    create_cycle(user, project, issue_3, mr_3, milestone, pipeline_3)
    deploy_master(user, project, environment: 'staging')
  end

  before(:all) do
    clean_frontend_fixtures('analytics/')
    clean_frontend_fixtures('cycle_analytics/')
  end

  default_stages = %w[issue plan review code test staging production]

  describe Groups::CycleAnalytics::EventsController, type: :controller do
    render_views

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data
      create_deployment

      sign_in(user)
    end

    default_stages.each do |endpoint|
      it "cycle_analytics/events/#{endpoint}.json" do
        get endpoint, params: { group_id: group, format: :json }

        expect(response).to be_successful
      end
    end
  end

  describe Groups::CycleAnalyticsController, type: :controller do
    render_views

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data
      create_deployment

      sign_in(user)
    end

    it 'cycle_analytics/mock_data.json' do
      get(:show, params: {
        group_id: group.name,
        cycle_analytics: { start_date: 30 }
      }, format: :json)

      expect(response).to be_successful
    end
  end

  describe Analytics::CycleAnalytics::StagesController, type: :controller do
    render_views

    let(:params) { { created_after: 3.months.ago, created_before: Time.now, group_id: group.full_path } }

    before do
      stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
      stub_licensed_features(cycle_analytics_for_groups: true)

      # Persist the default stages
      Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |params|
        group.cycle_analytics_stages.build(params).save!
      end

      prepare_cycle_analytics_data
      create_deployment

      additional_cycle_analytics_metrics

      sign_in(user)
    end

    it 'analytics/cycle_analytics/stages.json' do
      get(:index, params: { group_id: group.name }, format: :json)

      expect(response).to be_successful
    end

    Gitlab::Analytics::CycleAnalytics::DefaultStages.all.each do |stage|
      it "analytics/cycle_analytics/stages/#{stage[:name]}/records.json" do
        stage_id = group.cycle_analytics_stages.find_by(name: stage[:name]).id
        get(:records, params: params.merge({ id: stage_id }), format: :json)

        expect(response).to be_successful
      end

      it "analytics/cycle_analytics/stages/#{stage[:name]}/median.json" do
        stage_id = group.cycle_analytics_stages.find_by(name: stage[:name]).id
        get(:median, params: params.merge({ id: stage_id }), format: :json)

        expect(response).to be_successful
      end
    end
  end

  describe Analytics::CycleAnalytics::SummaryController, type: :controller do
    render_views

    let(:params) { { created_after: 3.months.ago, created_before: Time.now, group_id: group.full_path } }

    before do
      stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data

      sign_in(user)
    end

    it 'analytics/cycle_analytics/summary.json' do
      get(:show, params: params, format: :json)

      expect(response).to be_successful
    end
  end

  describe Analytics::TasksByTypeController, type: :controller do
    render_views

    let(:label) { create(:group_label, group: group) }
    let(:label2) { create(:group_label, group: group) }
    let(:label3) { create(:group_label, group: group) }

    before do
      5.times do |i|
        create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [label])
        create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [label2])
        create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [label3])
      end

      stub_licensed_features(type_of_work_analytics: true)
      stub_feature_flags(Gitlab::Analytics::TASKS_BY_TYPE_CHART_FEATURE_FLAG => true)

      group.add_maintainer(user)

      sign_in(user)
    end

    it 'analytics/type_of_work/tasks_by_type?created_before=":created_before"' do
      params = { group_id: group.full_path, label_ids: [label.id, label2.id, label3.id], created_after: 10.days.ago, subject: 'Issue' }

      get(:show, params: params, format: :json)

      expect(response).to be_successful
    end
  end
end
