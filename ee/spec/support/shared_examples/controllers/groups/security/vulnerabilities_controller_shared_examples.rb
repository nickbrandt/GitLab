# frozen_string_literal: true

shared_examples 'group vulnerability findings controller' do
  before do
    sign_in(user)
    stub_licensed_features(security_dashboard: true)
    group.add_developer(user)
  end

  describe 'GET index.json' do
    it 'returns vulnerabilities for all projects in the group' do
      # create projects for the group
      2.times do
        project = create(:project, namespace: group)
        pipeline = create(:ci_pipeline, :success, project: project)

        create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project, severity: :high)
      end

      # create an ungrouped project to ensure we don't include it
      project = create(:project)
      pipeline = create(:ci_pipeline, :success, project: project)
      create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project, severity: :high)

      get :index, params: { group_id: group }, format: :json

      expect(json_response.count).to be(2)
    end
  end

  describe 'GET history.json' do
    let(:params) { { group_id: group } }
    let(:project) { create(:project, namespace: group) }
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }

    subject { get :history, params: params, format: :json }

    before do
      travel_to(Time.zone.parse('2018-11-10')) do
        create(:vulnerabilities_occurrence,
                pipelines: [pipeline],
                project: project,
                report_type: :sast,
                severity: :critical)

        create(:vulnerabilities_occurrence,
                pipelines: [pipeline],
                project: project,
                report_type: :dependency_scanning,
                severity: :low)
      end

      travel_to(Time.zone.parse('2018-11-12')) do
        create(:vulnerabilities_occurrence,
                pipelines: [pipeline],
                project: project,
                report_type: :sast,
                severity: :critical)

        create(:vulnerabilities_occurrence,
                pipelines: [pipeline],
                project: project,
                report_type: :dependency_scanning,
                severity: :low)
      end
    end

    it 'returns vulnerability history within last 90 days' do
      travel_to(Time.zone.parse('2019-02-11')) do
        subject
      end

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['total']).to eq({ '2018-11-12' => 2 })
      expect(json_response['critical']).to eq({ '2018-11-12' => 1 })
      expect(json_response['low']).to eq({ '2018-11-12' => 1 })
      expect(response).to match_response_schema('vulnerabilities/history', dir: 'ee')
    end

    it 'returns empty history if there are no vulnerabilities within last 90 days' do
      travel_to(Time.zone.parse('2019-02-13')) do
        subject
      end

      expect(json_response).to eq({
        "undefined" => {},
        "info" => {},
        "unknown" => {},
        "low" => {},
        "medium" => {},
        "high" => {},
        "critical" => {},
        "total" => {}
      })
    end

    context 'with a report type filter' do
      let(:params) { { group_id: group, report_type: %w[sast] } }

      before do
        travel_to(Time.zone.parse('2019-02-11')) do
          subject
        end
      end

      it 'returns filtered history if filters are enabled' do
        expect(json_response['total']).to eq({ '2018-11-12' => 1 })
        expect(json_response['critical']).to eq({ '2018-11-12' => 1 })
        expect(json_response['low']).to eq({})
      end
    end
  end
end
