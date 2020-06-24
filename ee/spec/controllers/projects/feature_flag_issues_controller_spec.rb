# frozen_string_literal: true

require 'spec_helper'

describe Projects::FeatureFlagIssuesController do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  before do
    stub_licensed_features(feature_flags: true)
  end

  describe 'GET #index' do
    def setup
      feature_flag = create(:operations_feature_flag, project: project)
      issue = create(:issue, project: project)
      link = create(:feature_flag_issue, feature_flag: feature_flag, issue: issue)

      [feature_flag, issue, link]
    end

    def get_request(project, feature_flag)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        feature_flag_iid: feature_flag
      }

      get :index, params: params, format: :json
    end

    it 'returns linked issues' do
      feature_flag, issue = setup
      sign_in(developer)

      get_request(project, feature_flag)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match([a_hash_including({
        'id' => issue.id
      })])
    end

    it 'does not return linked issues for a reporter' do
      feature_flag, _, _ = setup
      sign_in(reporter)

      get_request(project, feature_flag)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'orders by feature_flag_issue id' do
      feature_flag = create(:operations_feature_flag, project: project)
      issue_a = create(:issue, project: project)
      issue_b = create(:issue, project: project)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_b)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_a)
      sign_in(developer)

      get_request(project, feature_flag)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |issue| issue['id'] }).to eq([issue_b.id, issue_a.id])
    end

    it 'returns the correct relation_path when the feature flag is linked to multiple issues' do
      feature_flag, issue_a, link_a = setup
      issue_b = create(:issue, project: project)
      link_b = create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_b)
      sign_in(developer)

      get_request(project, feature_flag)

      expect(response).to have_gitlab_http_status(:ok)
      actual = json_response.sort_by { |issue| issue['id'] }.map { |issue| issue.slice('id', 'relation_path') }
      expect(actual).to eq([{
        'id' => issue_a.id,
        'relation_path' => "/#{project.full_path}/-/feature_flags/#{feature_flag.iid}/issues/#{link_a.id}"
      }, {
        'id' => issue_b.id,
        'relation_path' => "/#{project.full_path}/-/feature_flags/#{feature_flag.iid}/issues/#{link_b.id}"
      }])
    end

    it 'returns the correct relation_path when multiple feature flags are linked to an issue' do
      feature_flag_a, issue, link = setup
      feature_flag_b = create(:operations_feature_flag, project: project)
      create(:feature_flag_issue, feature_flag: feature_flag_b, issue: issue)
      sign_in(developer)

      get_request(project, feature_flag_a)

      expect(response).to have_gitlab_http_status(:ok)
      actual = json_response.map { |issue| issue.slice('id', 'relation_path') }
      expect(actual).to eq([{
        'id' => issue.id,
        'relation_path' => "/#{project.full_path}/-/feature_flags/#{feature_flag_a.iid}/issues/#{link.id}"
      }])
    end

    it 'returns the correct relation_path when there are multiple linked feature flags and issues' do
      feature_flag_a, issue_a, _ = setup
      feature_flag_b, issue_b, link_b = setup
      feature_flag_c, issue_c, _ = setup
      link_a = create(:feature_flag_issue, feature_flag: feature_flag_b, issue: issue_a)
      link_c = create(:feature_flag_issue, feature_flag: feature_flag_b, issue: issue_c)
      create(:feature_flag_issue, feature_flag: feature_flag_a, issue: issue_b)
      create(:feature_flag_issue, feature_flag: feature_flag_a, issue: issue_c)
      create(:feature_flag_issue, feature_flag: feature_flag_c, issue: issue_a)
      create(:feature_flag_issue, feature_flag: feature_flag_c, issue: issue_b)
      sign_in(developer)

      get_request(project, feature_flag_b)

      expect(response).to have_gitlab_http_status(:ok)
      actual = json_response.sort_by { |issue| issue['id'] }.map { |issue| issue.slice('id', 'relation_path') }
      expect(actual).to eq([{
        'id' => issue_a.id,
        'relation_path' => "/#{project.full_path}/-/feature_flags/#{feature_flag_b.iid}/issues/#{link_a.id}"
      }, {
        'id' => issue_b.id,
        'relation_path' => "/#{project.full_path}/-/feature_flags/#{feature_flag_b.iid}/issues/#{link_b.id}"
      }, {
        'id' => issue_c.id,
        'relation_path' => "/#{project.full_path}/-/feature_flags/#{feature_flag_b.iid}/issues/#{link_c.id}"
      }])
    end

    it 'does not make N+1 queries' do
      feature_flag, _, _ = setup
      sign_in(developer)

      control_count = ActiveRecord::QueryRecorder.new { get_request(project, feature_flag) }.count

      issue_b = create(:issue, project: project)
      issue_c = create(:issue, project: project)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_b)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_c)

      expect { get_request(project, feature_flag) }.not_to exceed_query_limit(control_count)
    end

    it 'returns only issues readable by the user' do
      feature_flag, _, _ = setup
      issue_b = create(:issue, project: project, author: developer)
      create(:feature_flag_issue, feature_flag: feature_flag, issue: issue_b)
      allow(Ability).to receive(:issues_readable_by_user) do |issues, user, _filters|
        issues.where(author: user)
      end
      sign_in(developer)

      get_request(project, feature_flag)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.map { |issue| issue['id'] }).to eq([issue_b.id])
    end

    it 'returns not found when the feature is off' do
      stub_feature_flags(feature_flags_issue_links: false)
      feature_flag, _, _ = setup
      sign_in(developer)

      get_request(project, feature_flag)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    context 'when feature flags are unlicensed' do
      before do
        stub_licensed_features(feature_flags: false)
      end

      it 'does not return linked issues' do
        feature_flag, _, _ = setup
        sign_in(developer)

        get_request(project, feature_flag)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
