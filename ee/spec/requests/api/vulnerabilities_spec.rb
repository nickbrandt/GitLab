# frozen_string_literal: true

require 'spec_helper'

describe API::Vulnerabilities do
  set(:project) { create(:project, :public) }
  set(:user) { create(:user) }

  let(:pipeline) { create(:ci_empty_pipeline, status: :created, project: project) }
  let(:pipeline_without_vulnerabilities) { create(:ci_pipeline_without_jobs, status: :created, project: project) }

  let(:build_ds) { create(:ci_build, :success, name: 'ds_job', pipeline: pipeline, project: project) }
  let(:build_sast) { create(:ci_build, :success, name: 'sast_job', pipeline: pipeline, project: project) }

  let(:ds_report) { pipeline.security_reports.reports["dependency_scanning"] }
  let(:sast_report) { pipeline.security_reports.reports["sast"] }

  let(:dismissal) do
    create(:vulnerability_feedback, :dismissal, :sast,
      project: project,
      pipeline: pipeline,
      project_fingerprint: sast_report.occurrences.first.project_fingerprint,
      vulnerability_data: sast_report.occurrences.first.raw_metadata
    )
  end

  before do
    stub_licensed_features(security_dashboard: true, sast: true, dependency_scanning: true, container_scanning: true)

    create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds, project: project)
    create(:ee_ci_job_artifact, :sast, job: build_sast, project: project)
    dismissal
  end

  describe "GET /projects/:id/vulnerabilities" do
    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'returns all non-dismissed vulnerabilities' do
        occurrence_count = (sast_report.occurrences.count + ds_report.occurrences.count - 1).to_s

        get api("/projects/#{project.id}/vulnerabilities?per_page=40", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')

        expect(response.headers['X-Total']).to eq occurrence_count

        expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[dependency_scanning sast]
      end

      it 'does not have N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          get api("/projects/#{project.id}/vulnerabilities", user), params: { report_type: 'dependency_scanning' }
        end.count

        expect { get api("/projects/#{project.id}/vulnerabilities", user) }.not_to exceed_query_limit(control_count)
      end

      describe 'filtering' do
        it 'returns vulnerabilities with sast report_type' do
          occurrence_count = (sast_report.occurrences.count - 1).to_s

          get api("/projects/#{project.id}/vulnerabilities", user), params: { report_type: 'sast' }

          expect(response).to have_gitlab_http_status(200)

          expect(response.headers['X-Total']).to eq occurrence_count

          expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[sast]

          expect(json_response.first['name']).to eq 'Predictable pseudorandom number generator'
        end

        it 'returns vulnerabilities with dependency_scanning report_type' do
          occurrence_count = ds_report.occurrences.count.to_s

          get api("/projects/#{project.id}/vulnerabilities", user), params: { report_type: 'dependency_scanning' }

          expect(response).to have_gitlab_http_status(200)

          expect(response.headers['X-Total']).to eq occurrence_count

          expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[dependency_scanning]

          expect(json_response.first['name']).to eq 'DoS by CPU exhaustion when using malicious SSL packets'
        end

        it 'returns dismissed vulnerabilities with `all` scope' do
          occurrence_count = (sast_report.occurrences.count + ds_report.occurrences.count).to_s

          get api("/projects/#{project.id}/vulnerabilities", user), params: { per_page: 40, scope: 'all' }

          expect(response).to have_gitlab_http_status(200)

          expect(response.headers['X-Total']).to eq occurrence_count
        end

        it 'returns vulnerabilities with low severity' do
          get api("/projects/#{project.id}/vulnerabilities", user), params: { per_page: 40, severity: 'low' }

          expect(response).to have_gitlab_http_status(200)

          expect(json_response.map { |v| v['severity'] }.uniq).to eq %w[low]
        end

        it 'returns vulnerabilities with high confidence' do
          get api("/projects/#{project.id}/vulnerabilities", user), params: { per_page: 40, confidence: 'high' }

          expect(response).to have_gitlab_http_status(200)

          expect(json_response.map { |v| v['confidence'] }.uniq).to eq %w[high]
        end

        context 'when pipeline_id is supplied' do
          it 'returns vulnerabilities from supplied pipeline' do
            occurrence_count = (sast_report.occurrences.count + ds_report.occurrences.count - 1).to_s

            get api("/projects/#{project.id}/vulnerabilities", user), params: { per_page: 40, pipeline_id: pipeline.id }

            expect(response).to have_gitlab_http_status(200)

            expect(response.headers['X-Total']).to eq occurrence_count
          end

          context 'pipeline has no reports' do
            it 'returns empty results' do
              get api("/projects/#{project.id}/vulnerabilities", user), params: { per_page: 40, pipeline_id: pipeline_without_vulnerabilities.id }

              expect(json_response).to eq []
            end
          end

          context 'with unknown pipeline' do
            it 'returns empty results' do
              get api("/projects/#{project.id}/vulnerabilities", user), params: { per_page: 40, pipeline_id: 0 }

              expect(json_response).to eq []
            end
          end
        end
      end
    end

    context 'with authorized user without read permissions' do
      before do
        project.add_reporter(user)
        stub_licensed_features(security_dashboard: false, sast: true, dependency_scanning: true, container_scanning: true)
      end

      it 'responds with 403 Forbidden' do
        get api("/projects/#{project.id}/vulnerabilities", user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'with no project access' do
      it 'responds with 404 Not Found' do
        private_project = create(:project)

        get api("/projects/#{private_project.id}/vulnerabilities", user)

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
