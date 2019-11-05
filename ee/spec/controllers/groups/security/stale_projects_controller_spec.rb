# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::StaleProjectsController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { group }
    let(:security_dashboard_action) { get :index, params: { group_id: group }, format: :json }
  end

  describe '#index' do
    before do
      stub_licensed_features(security_dashboard: true)

      group.add_developer(user)
      sign_in(user)
    end

    subject { get :index, params: { group_id: group }, format: :json }

    it "responds with a list of the group's most vulnerable projects" do
      Timecop.freeze do
        _ungrouped_project = create(:project)
        unconfigured_project = create(:project, namespace: group)

        up_to_date_project = create(:project, namespace: group)
        create(:ci_build, :dast, status: :success, finished_at: Time.current, project: up_to_date_project)
        create(:ci_build, :sast, status: :success, finished_at: Time.current, project: up_to_date_project)
        create(:ci_build, :container_scanning, status: :success, finished_at: Time.current, project: up_to_date_project)
        create(:ci_build, :dependency_scanning, status: :success, finished_at: Time.current, project: up_to_date_project)

        out_of_date_project = create(:project, namespace: group)
        create(:ci_build, :dast, status: :success, finished_at: Time.current - 6.days.ago, project: out_of_date_project)
        create(:ci_build, :sast, status: :success, finished_at: Time.current - 13.days.ago, project: out_of_date_project)
        create(:ci_build, :container_scanning, status: :success, finished_at: Time.current - 13.days.ago, project: out_of_date_project)
        create(:ci_build, :dependency_scanning, status: :success, finished_at: Time.current - 13.days.ago, project: out_of_date_project)

        subject

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.count).to be(2)

        out_of_date_project_data = json_response.find { |project| project['id'] == out_of_date_project.id }
        unconfigured_project_data = json_response.find { |project| project['id'] == unconfigured_project.id }

        expect(out_of_date_project_data['out_of_date_scans']).to contain_exactly(
          { 'scan_name' => 'dast', 'days_since_last_scan' => 6 },
          { 'scan_name' => 'sast', 'days_since_last_scan' => 13 },
          { 'scan_name' => 'container_scanning', 'days_since_last_scan' => 13 },
          { 'scan_name' => 'dependency_scanning', 'days_since_last_scan' => 13 }
        )
        expect(unconfigured_project_data['unconfigured_scans']).to eq([
          'sast', 'dast', 'container_scanning', 'dependency_scanning'
        ])
      end
    end

    it 'only considers successful builds when finding out-of-date scans'

    it 'does not include archived or deleted projects'
      # archived_project = create(:project, :archived, namespace: group)
      # deleted_project = create(:project, namespace: group, pending_delete: true)
      # create(:vulnerabilities_occurrence, project: archived_project)
      # create(:vulnerabilities_occurrence, project: deleted_project)

      # subject

      # expect(response).to have_gitlab_http_status(200)
      # expect(json_response).to be_empty
  end
end
