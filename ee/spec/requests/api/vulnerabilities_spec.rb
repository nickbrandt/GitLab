# frozen_string_literal: true

require 'spec_helper'

describe API::Vulnerabilities do
  set(:user) { create(:user) }
  
  before do
    stub_licensed_features(security_dashboard: true, sast: true, dependency_scanning: true, container_scanning: true)
  end

  shared_examples 'GET /:source_type/:id/vulnerabilities' do |source_type|
    let(:url) { "/#{source_type}/#{source.id}/vulnerabilities" }

    it 'does not have N+1 queries' do
      control_count = ActiveRecord::QueryRecorder.new do
        get api(url, user), params: { report_type: 'sast', severity: 'medium' }
      end.count

      expect { get api(url, user) }.not_to exceed_query_limit(control_count)
    end

    # context 'without filters' do
    #   it 'returns all vulnerabilities' do
    #     get api(url, user)

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq(total_count.to_s)
    #   end
    # end

    # context 'with report type filter' do
    #   it 'returns vulnerabilities with sast report type' do
    #     get api(url, user), params: { report_type: 'sast' }

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq(sast_count.to_s)
    #     expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[sast]
    #   end
    # end

    # context 'with severity filter' do
    #   it 'returns vulnerabilities with severity' do
    #     get api(url, user), params: { severity: 'high' }

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq(high_severity_count.to_s)
    #     expect(json_response.map { |v| v['severity'] }.uniq).to match_array %w[high]
    #   end
    # end

    # context 'with confidence filter' do
    #   it 'returns vulnerabilities with given confidence' do
    #     get api(url, user), params: { confidence: 'low' }
    
    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq(low_confidence_count.to_s)
    #     expect(json_response.map { |v| v['confidence'] }.uniq).to match_array %w[low]
    #   end
    # end

    # xcontext 'with pipeline id' do
    #   it 'returns vulnerabilities for pipeline' do
    #     get api(url, user), params: { pipeline_id: 1 }

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq '2'
    #     expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[sast]
    #     expect(json_response.map { |v| v['severity'] }.uniq).to match_array %w[high]
    #     expect(json_response.map { |v| v['confidence'] }.uniq).to match_array %w[unknown]
    #   end
    # end

    # xcontext 'with scope filter' do
    #   it 'returns vulnerabilities with given scope' do
    #     get api(url, user), params: { scope: 'dismissed' }

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq '2'
    #     expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[dast sast]
    #     expect(json_response.map { |v| v['severity'] }.uniq).to match_array %w[high]
    #     expect(json_response.map { |v| v['confidence'] }.uniq).to match_array %w[unknown]
    #   end
    # end

    # context 'with all filters' do
    #   it 'returns vulnerabilities with requested attributes' do
    #     get api(url, user), params: { report_type: 'sast', severity: 'medium', confidence: 'medium', scope: 'all' }

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq(sast_med_sev_med_conf.to_s)
    #     expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[sast]
    #     expect(json_response.map { |v| v['severity'] }.uniq).to match_array %w[medium]
    #     expect(json_response.map { |v| v['confidence'] }.uniq).to match_array %w[medium]
    #   end
    # end

    # context 'with some filters' do
    #   it 'returns vulnerabilities with requested attributes' do
    #     get api(url, user), params: { report_type: 'sast', confidence: 'medium' }

    #     expect(response).to have_gitlab_http_status(200)
    #     expect(response).to include_pagination_headers
    #     expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
    #     expect(response.headers['X-Total']).to eq(sast_med_conf_count.to_s)
    #     expect(json_response.map { |v| v['report_type'] }.uniq).to match_array %w[sast]
    #     expect(json_response.map { |v| v['confidence'] }.uniq).to match_array %w[medium]
    #   end
    # end

    context 'with unknown resource' do
      it 'responds with 404' do
        get api("/#{source_type}/0/vulnerabilities", user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  def group_helper(group)

  end

  context 'with Group resource' do
    set(:group) { create(:group, :public) }
    let!(:project1) { create(:project, :public, group: group) }
    let!(:project2) { create(:project, :public, group: group) }
    let!(:pipeline1) { create(:ci_empty_pipeline, status: :success, project: project1) }
    let!(:pipeline2) { create(:ci_empty_pipeline, status: :success, project: project2) }
    let!(:vulnerability1) { create(:vulnerabilities_occurrence, project: project1, pipelines: [pipeline1]) }

    before do
      create(:vulnerabilities_occurrence,
        project: project2,
        pipelines: [pipeline2],
        severity: :medium
      )
      create(:vulnerabilities_occurrence,
        project: project2,
        pipelines: [pipeline2],
        report_type: :dast,
        confidence: :low
      )
      create(:vulnerability_feedback, :dismissal, :sast,
        project: project1,
        pipeline: pipeline1,
        project_fingerprint: vulnerability1.project_fingerprint
      )

      group.add_developer(user)
    end

    it_behaves_like 'GET /:source_type/:id/vulnerabilities', 'groups' do
      let(:source) { group }
      let(:total_count) { 3 }
      let(:sast_count) { 2 }
      let(:high_severity_count) { 2 }
      let(:low_confidence_count) { 1 }
      let(:sast_med_sev_med_conf) { 1 }
      let(:sast_med_conf_count) { 2 }
    end
  end

  describe 'Vulnerabilities Project API' do
    set(:project) { create(:project, :public) }
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
      create(:ee_ci_job_artifact, :dependency_scanning, job: build_ds, project: project)
      create(:ee_ci_job_artifact, :sast, job: build_sast, project: project)
      dismissal
      project.add_developer(user)
    end

    it_behaves_like 'GET /:source_type/:id/vulnerabilities', 'projects' do
      let(:source) { project }
      let(:all_occurrences) { sast_report.occurrences + ds_report.occurrences }
      let(:total_count) { all_occurrences.count - 1 }
      let(:sast_count) { sast_report.occurrences.count - 1 }
      let(:high_severity_count) { all_occurrences.select { |v| v.severity == 'high' }.count }
      let(:low_confidence_count) { all_occurrences.select { |v| v.confidence == 'low' }.count }
      let(:sast_med_sev_med_conf) { sast_report.occurrences.select { |v| v.severity == 'medium' && v.confidence == 'medium' }.count }
      let(:sast_med_conf_count) { sast_report.occurrences.select { |v| v.confidence == 'medium' }.count }
    end
  end

  xdescribe "GET /projects/:id/vulnerabilities" do

    context 'with an authorized user with proper permissions' do

      xit 'does not have N+1 queries' do
        control_count = ActiveRecord::QueryRecorder.new do
          get api("/projects/#{project.id}/vulnerabilities", user), params: { report_type: 'dependency_scanning' }
        end.count

        expect { get api("/projects/#{project.id}/vulnerabilities", user) }.not_to exceed_query_limit(control_count)
      end

      describe 'filtering' do
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
