# frozen_string_literal: true
require 'spec_helper'

describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  include JavaScriptFixturesHelpers

  let(:group) { create(:group)}
  let(:project) { create(:project, :repository, namespace: group) }
  let(:user) { create(:user, :admin) }
  let(:issue) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }
  let(:build) { create(:ci_build, :success, pipeline: pipeline, author: user) }

  let!(:issue_1) { create(:issue, project: project, created_at: 5.days.ago) }
  let!(:issue_2) { create(:issue, project: project, created_at: 4.days.ago) }
  let!(:issue_3) { create(:issue, project: project, created_at: 3.days.ago) }

  let!(:mr_1) { create_merge_request_closing_issue(user, project, issue_1) }
  let!(:mr_2) { create_merge_request_closing_issue(user, project, issue_2) }
  let!(:mr_3) { create_merge_request_closing_issue(user, project, issue_3) }

  def prepare_cycle_analytics_data
    group.add_maintainer(user)
    project.add_maintainer(user)

    create_cycle(user, project, issue, mr, milestone, pipeline)
    create_cycle(user, project, issue_2, mr_2, milestone, pipeline)

    create_commit_referencing_issue(issue_1)
    create_commit_referencing_issue(issue_2)

    create_merge_request_closing_issue(user, project, issue_1)
    create_merge_request_closing_issue(user, project, issue_2)

    merge_merge_requests_closing_issue(user, project, issue_3)

    deploy_master(user, project, environment: 'staging')
    deploy_master(user, project)
  end

  before(:all) do
    clean_frontend_fixtures('analytics/')
  end

  describe Groups::CycleAnalytics::EventsController, type: :controller do
    render_views

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data

      sign_in(user)
    end

    default_stages = %w[issue plan review code test staging production]

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

    before do
      stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
      stub_licensed_features(cycle_analytics_for_groups: true)

      sign_in(user)
    end

    it 'analytics/cycle_analytics/stages.json' do
      get(:index, params: { group_id: group.name }, format: :json)

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

    it 'analytics/type_of_work/tasks_by_type.json' do
      params = { group_id: group.full_path, label_ids: [label.id, label2.id, label3.id], created_after: 10.days.ago, subject: 'Issue' }

      get(:show, params: params, format: :json)

      expect(response).to be_successful
    end
  end
end
