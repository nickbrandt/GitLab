# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::VulnerabilitiesController do
  include ApiHelpers

  set(:group) { create(:group) }
  set(:group_other) { create(:group) }
  set(:user) { create(:user) }
  set(:project_dev) { create(:project, :private, :repository, group: group) }
  set(:project_guest) { create(:project, :private, :repository, group: group) }
  set(:project_other) { create(:project, :public, :repository, group: group_other) }
  let(:projects) { [project_dev, project_guest, project_other] }

  before do
    sign_in(user)
  end

  describe 'GET index.json' do
    subject { get :index, params: { group_id: group }, format: :json }

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user has guest access' do
        before do
          group.add_guest(user)
        end

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user has developer access' do
        before do
          group.add_developer(user)
        end

        context 'when no page request' do
          before do
            projects.each do |project|
              create_vulnerabilities(1, project)
            end
          end

          it "returns a list of vulnerabilities" do
            subject

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 2
            expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
          end
        end

        context 'when page requested' do
          before do
            projects.each do |project|
              create_vulnerabilities(11, project)
            end
          end

          it "returns a list of vulnerabilities" do
            get :index, params: { group_id: group, page: 2 }, format: :json

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 2
          end
        end

        context 'with vulnerability feedback' do
          it "avoids N+1 queries" do
            create_vulnerabilities(2, project_dev, with_feedback: true)

            control_count = ActiveRecord::QueryRecorder.new { get_summary }

            create_vulnerabilities(2, project_guest, with_feedback: true)

            expect { get_summary }.not_to exceed_all_query_limit(control_count)
          end

          private

          def get_summary
            get :index, params: { group_id: group }, format: :json
          end
        end

        context 'with multiple report types' do
          before do
            projects.each do |project|
              create_vulnerabilities(2, project_guest, { report_type: :sast })
              create_vulnerabilities(1, project_dev, { report_type: :dependency_scanning })
            end
          end

          it "returns a list of vulnerabilities for all report types without filter" do
            subject

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 3
            expect(json_response.map { |v| v['report_type'] }.uniq).to contain_exactly('sast', 'dependency_scanning')
            expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
          end

          it "returns a list of vulnerabilities for sast only if filter is enabled" do
            get :index, params: { group_id: group, report_type: ['sast'] }, format: :json

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Array)
            expect(json_response.length).to eq 2
            expect(json_response.map { |v| v['report_type'] }.uniq).to contain_exactly('sast')
            expect(response).to match_response_schema('vulnerabilities/occurrence_list', dir: 'ee')
          end

          it "returns a list of vulnerabilities of all types with multi filter" do
            get :index, params: { group_id: group, report_type: %w[sast dependency_scanning] }, format: :json

            expect(json_response.length).to eq 3
            expect(json_response.map { |v| v['report_type'] }.uniq).to contain_exactly('sast', 'dependency_scanning')
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
      end
    end
  end

  describe 'GET summary.json' do
    subject { get :summary, params: { group_id: group }, format: :json }

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)

        pipeline = create(:ci_pipeline, :success, project: project_dev)

        create_list(:vulnerabilities_occurrence, 3,
                    pipelines: [pipeline], project: project_dev, report_type: :sast, severity: :high)

        create_list(:vulnerabilities_occurrence, 1,
                    pipelines: [pipeline], project: project_dev, report_type: :dependency_scanning, severity: :low)

        create_list(:vulnerabilities_occurrence, 2,
                    pipelines: [pipeline], project: project_guest, report_type: :dependency_scanning, severity: :low)

        create_list(:vulnerabilities_occurrence, 1,
                    pipelines: [pipeline], project: project_guest, report_type: :dast, severity: :medium)

        create_list(:vulnerabilities_occurrence, 1,
                    pipelines: [pipeline], project: project_other, report_type: :dast, severity: :low)
      end

      context 'when user has guest access' do
        before do
          group.add_guest(user)
        end

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user has developer access' do
        before do
          group.add_developer(user)
        end

        it 'returns vulnerabilities counts' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Hash)
          expect(json_response['high']).to eq(3)
          expect(json_response['low']).to eq(4)
          expect(json_response['medium']).to eq(1)
          expect(response).to match_response_schema('vulnerabilities/summary', dir: 'ee')
        end

        context 'with enabled filters' do
          it 'returns counts for filtered vulnerabilities' do
            get :summary, params: { group_id: group, report_type: %w[sast dast], severity: %[high low] }, format: :json

            expect(response).to have_gitlab_http_status(200)
            expect(json_response).to be_an(Hash)
            expect(json_response['high']).to eq(3)
            expect(json_response['low']).to eq(1)
            expect(json_response['medium']).to eq(1)
            expect(response).to match_response_schema('vulnerabilities/summary', dir: 'ee')
          end
        end
      end
    end
  end

  describe 'GET history.json' do
    subject { get :history, params: { group_id: group }, format: :json }

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)

        travel_to(Time.zone.parse('2018-11-10')) do
          pipeline_1 = create(:ci_pipeline, :success, project: project_dev)
          pipeline_2 = create(:ci_pipeline, :success, project: project_dev)

          create_list(:vulnerabilities_occurrence, 2,
            pipelines: [pipeline_1], project: project_dev, report_type: :sast, severity: :high)

          create_list(:vulnerabilities_occurrence, 1,
            pipelines: [pipeline_1], project: project_dev, report_type: :dependency_scanning, severity: :low)

          create_list(:vulnerabilities_occurrence, 1,
            pipelines: [pipeline_1, pipeline_2], project: project_dev, report_type: :sast, severity: :critical)

          create_list(:vulnerabilities_occurrence, 1,
            pipelines: [pipeline_1, pipeline_2], project: project_dev, report_type: :dependency_scanning, severity: :low)
        end

        travel_to(Time.zone.parse('2018-11-12')) do
          pipeline = create(:ci_pipeline, :success, project: project_dev)

          create_list(:vulnerabilities_occurrence, 2,
            pipelines: [pipeline], project: project_dev, report_type: :dependency_scanning, severity: :low)

          create_list(:vulnerabilities_occurrence, 1,
            pipelines: [pipeline], project: project_dev, report_type: :dast, severity: :medium)

          create_list(:vulnerabilities_occurrence, 1,
            pipelines: [pipeline], project: project_dev, report_type: :dast, severity: :low)
        end
      end

      context 'when user has guest access' do
        before do
          group.add_guest(user)
        end

        it 'returns 403' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user has developer access' do
        before do
          group.add_developer(user)
        end

        it 'returns vulnerability history within last 90 days' do
          travel_to(Time.zone.parse('2019-02-10')) do
            subject
          end

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Hash)
          expect(json_response['total']).to eq({ '2018-11-10' => 5, '2018-11-12' => 4 })
          expect(json_response['critical']).to eq({ '2018-11-10' => 1 })
          expect(json_response['high']).to eq({ '2018-11-10' => 2 })
          expect(json_response['medium']).to eq({ '2018-11-12' => 1 })
          expect(json_response['low']).to eq({ '2018-11-10' => 2, '2018-11-12' => 3 })
          expect(response).to match_response_schema('vulnerabilities/history', dir: 'ee')
        end

        it 'returns empty history if there are no vulnerabilities within last 90 days' do
          travel_to(Time.zone.parse('2019-02-13')) do
            subject
          end

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Hash)
          expect(json_response).to eq({
            "undefined" => {},
            "ignore" => {},
            "unknown" => {},
            "experimental" => {},
            "low" => {},
            "medium" => {},
            "high" => {},
            "critical" => {},
            "total" => {}
          })
          expect(response).to match_response_schema('vulnerabilities/history', dir: 'ee')
        end

        it 'returns filtered history if filters are enabled' do
          travel_to(Time.zone.parse('2019-02-10')) do
            get :history, params: { group_id: group, report_type: %w[dependency_scanning sast] }, format: :json
          end

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Hash)
          expect(json_response['total']).to eq({ '2018-11-10' => 5, '2018-11-12' => 2 })
          expect(json_response['critical']).to eq({ '2018-11-10' => 1 })
          expect(json_response['high']).to eq({ '2018-11-10' => 2 })
          expect(json_response['medium']).to eq({})
          expect(json_response['low']).to eq({ '2018-11-10' => 2, '2018-11-12' => 2 })
          expect(response).to match_response_schema('vulnerabilities/history', dir: 'ee')
        end
      end
    end
  end
end
