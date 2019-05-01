# frozen_string_literal: true

require 'spec_helper'

describe API::Vulnerabilities do
  set(:project) { create(:project, :public) }
  set(:user) { create(:user) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
  end

  let(:build_ds) { create(:ci_build, :success, name: 'ds_job', pipeline: pipeline, project: project) }
  let(:build_sast) { create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) }

  before do
    create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds, project: project)
    create(:ee_ci_job_artifact, :sast, job: build_sast, project: project)
  end

  describe "GET /projects/:id/vulnerabilities" do
    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
        stub_licensed_features(security_dashboard: true, sast: true, dependency_scanning: true, container_scanning: true)
      end

      it 'returns all vulnerabilities' do
        get api("/projects/#{project.id}/vulnerabilities?per_page=40", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')

        expect(response.headers['X-Total']).to eq('37')
        expect(response.headers['X-Total-Pages']).to eql('1')

        expect(json_response.count).to eq 37
        expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[dependency_scanning sast]
      end

      describe 'filtering' do
        it 'returns vulnerabilities with sast report_type' do
          get api("/projects/#{project.id}/vulnerabilities", user), params: { report_type: 'sast' }

          expect(response).to have_gitlab_http_status(200)

          expect(json_response.count).to eq 20
          expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[sast]

          expect(json_response.first['name']).to eq 'Probable insecure usage of temp file/directory.'
        end

        it 'returns vulnerabilities with dependency_scanning report_type' do
          get api("/projects/#{project.id}/vulnerabilities", user), params: { report_type: 'dependency_scanning' }

          expect(response).to have_gitlab_http_status(200)

          expect(json_response.count).to eq 4
          expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[dependency_scanning]

          expect(json_response.first['name']).to eq 'DoS by CPU exhaustion when using malicious SSL packets'
        end
      end
    end

    context 'with authorized user without read permissions' do
      before do
        project.add_reporter(user)
        stub_licensed_features(security_dashboard: false, sast: true, dependency_scanning: true, container_scanning: true)
      end

      it 'responds with 404 Not Found' do
        get api("/projects/#{project.id}/vulnerabilities", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'responds with 404 Not Found' do
        get api("/projects/#{project.id}/vulnerabilities", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with unknown project' do
      it 'responds with 404 Not Found' do
        get api("/projects/0/vulnerabilities", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
