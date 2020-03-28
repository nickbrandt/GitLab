# frozen_string_literal: true
require 'spec_helper'

describe 'value stream analytics events' do
  let(:user) { create(:user) }
  let(:group) { create(:group)}
  let(:project) { create(:project, :repository, namespace: group, public_builds: false) }
  let(:issue) { create(:issue, project: project, created_at: 2.days.ago) }

  describe 'GET /:namespace/-/value_stream_analytics/events/:stage' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
      group.add_developer(user)
      project.add_developer(user)

      3.times do |count|
        Timecop.freeze(Time.now + count.days) do
          create_cycle
        end
      end

      deploy_master(user, project)

      login_as(user)
    end

    context 'when date range parameters are given' do
      it 'filter by `created_after`' do
        params = { created_after: issue.created_at - 5.days }

        get group_cycle_analytics_issue_path(group, params: params, format: :json)

        expect(json_response['events']).not_to be_empty
      end

      it 'filters by `created_after` where no events should be found' do
        params = { created_after: issue.created_at + 5.days }

        get group_cycle_analytics_issue_path(group, params: params, format: :json)

        expect(json_response['events']).to be_empty
      end

      it 'filter by `created_after` and `created_before`' do
        params = { created_after: issue.created_at - 5.days, created_before: issue.created_at + 5.days }

        get group_cycle_analytics_issue_path(group, params: params, format: :json)

        expect(json_response['events']).not_to be_empty
      end

      it 'raises error when date cannot be parsed' do
        params = { created_after: 'invalid' }

        expect do
          get group_cycle_analytics_issue_path(group, params: params, format: :json)
        end.to raise_error(ArgumentError)
      end
    end

    it 'lists the issue events' do
      get group_cycle_analytics_issue_path(group, format: :json)

      first_issue_iid = project.issues.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the plan events' do
      get group_cycle_analytics_plan_path(group, format: :json)

      first_issue_iid = project.issues.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    it 'lists the code events' do
      get group_cycle_analytics_code_path(group, format: :json)

      expect(json_response['events']).not_to be_empty

      first_mr_iid = project.merge_requests.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the test events', :sidekiq_might_not_need_inline do
      get group_cycle_analytics_test_path(group, format: :json)

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['date']).not_to be_empty
    end

    it 'lists the review events' do
      get group_cycle_analytics_review_path(group, format: :json)

      first_mr_iid = project.merge_requests.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_mr_iid)
    end

    it 'lists the staging events', :sidekiq_might_not_need_inline do
      get group_cycle_analytics_staging_path(group, format: :json)

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['date']).not_to be_empty
    end

    it 'lists the production events', :sidekiq_might_not_need_inline do
      get group_cycle_analytics_production_path(group, format: :json)

      first_issue_iid = project.issues.sort_by_attribute(:created_desc).pluck(:iid).first.to_s

      expect(json_response['events']).not_to be_empty
      expect(json_response['events'].first['iid']).to eq(first_issue_iid)
    end

    context 'specific branch' do
      it 'lists the test events', :sidekiq_might_not_need_inline do
        branch = project.merge_requests.first.source_branch

        get group_cycle_analytics_test_path(group, format: :json, branch: branch)

        expect(json_response['events']).not_to be_empty
        expect(json_response['events'].first['date']).not_to be_empty
      end
    end
  end

  def create_cycle
    milestone = create(:milestone, project: project)
    issue.update(milestone: milestone)
    mr = create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}")

    pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr)
    pipeline.run

    create(:ci_build, pipeline: pipeline, status: :success, author: user)
    create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(user, project, issue)

    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)
  end
end
