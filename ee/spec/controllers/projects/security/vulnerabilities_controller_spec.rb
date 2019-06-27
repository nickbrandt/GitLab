# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
  include ApiHelpers

  describe 'GET index.json' do
    context 'when security dashboard feature is disabled' do
      it 'returns 404' do
        user = create(:user)
        project = create(:project)
        project.add_maintainer(user)

        sign_in(user)
        stub_licensed_features(security_dashboard: false)

        get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is enabled' do
      context 'when user has guest access' do
        it 'returns 403' do
          user = create(:user)
          project = create(:project)
          project.add_guest(user)

          sign_in(user)
          stub_licensed_features(security_dashboard: true)

          get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user has developer access' do
        context 'when no page request' do
          it "returns a list of vulnerabilities" do
            user = create(:user)
            project = create(:project)
            project.add_developer(user)
            create_vulnerabilities(3, project)

            sign_in(user)
            stub_licensed_features(security_dashboard: true)

            get :index, params: { namespace_id: project.namespace, project_id: project }, format: :json

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 3
            expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
          end
        end

        #     context 'when page requested' do
        #       it "returns a list of vulnerabilities" do
        #     context 'with vulnerability feedback' do
        #       it "avoids N+1 queries", :with_request_store do
        #     context 'with multiple report types' do
        #       it "returns a list of vulnerabilities for all report types without filter" do
        #       it "returns a list of vulnerabilities for sast only if filter is enabled" do
        #       it "returns a list of vulnerabilities of all types with multi filter" do
      end
    end


    # describe 'GET summary.json' do
    # context 'when security dashboard feature is disabled' do
    #   it 'returns 404' do
    # context 'when security dashboard feature is enabled' do
    #   context 'when user has guest access' do
    #     it 'returns 403' do
    #   context 'when user has developer access' do
    #     it 'returns vulnerabilities counts for all report types' do
    #     context 'with enabled filters' do
    #       it 'returns counts for filtered vulnerabilities' do

    # describe 'GET history.json' do
    # context 'when security dashboard feature is disabled' do
    #   it 'returns 404' do
    # context 'when security dashboard feature is enabled' do
    #   context 'when user has guest access' do
    #     it 'returns 403' do
    #   context 'when user has developer access' do
    #     it 'returns vulnerability history within last 90 days' do
    #     it 'returns empty history if there are no vulnerabilities within last 90 days' do
    #     it 'returns filtered history if filters are enabled' do
    # end
  end
end

def create_vulnerabilities(count, project, options = {})
  report_type = options[:report_type] || :sast
  pipeline = create(:ci_pipeline, :success, project: project)
  vulnerabilities = create_list(:vulnerabilities_occurrence, count, report_type: report_type, pipelines: [pipeline], project: project)
  return vulnerabilities unless options[:with_feedback]

  vulnerabilities.each do |occurrence|
    create(:vulnerability_feedback, report_type, :dismissal,
            pipeline: pipeline,
            project: project_dev,
            project_fingerprint: occurrence.project_fingerprint)

    create(:vulnerability_feedback, report_type, :issue,
            pipeline: pipeline,
            issue: create(:issue, project: project),
            project: project_dev,
            project_fingerprint: occurrence.project_fingerprint)
  end
end
