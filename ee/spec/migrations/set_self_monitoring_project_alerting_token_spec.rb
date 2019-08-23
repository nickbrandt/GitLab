# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190809072552_set_self_monitoring_project_alerting_token.rb')

describe SetSelfMonitoringProjectAlertingToken, :migration do
  let(:application_settings) { table(:application_settings) }
  let(:projects)             { table(:projects) }
  let(:namespaces)           { table(:namespaces) }

  let(:namespace) do
    namespaces.create!(
      path: 'gitlab-instance-administrators',
      name: 'GitLab Instance Administrators'
    )
  end

  let(:project) do
    projects.create!(
      namespace_id: namespace.id,
      name: 'GitLab Instance Administration'
    )
  end

  describe 'down' do
    before do
      application_settings.create!(instance_administration_project_id: project.id)

      stub_licensed_features(prometheus_alerts: true)
    end

    it 'destroys token' do
      migrate!

      token = Alerting::ProjectAlertingSetting.where(project_id: project.id).first!.token
      expect(token).to be_present

      schema_migrate_down!

      expect(Alerting::ProjectAlertingSetting.count).to eq(0)
    end
  end

  describe 'up' do
    context 'when instance administration project present' do
      before do
        application_settings.create!(instance_administration_project_id: project.id)

        stub_licensed_features(prometheus_alerts: true)
      end

      it 'sets the alerting token' do
        migrate!

        token = Alerting::ProjectAlertingSetting.where(project_id: project.id).first!.token

        expect(token).to be_present
      end
    end

    context 'when instance administration project not present' do
      it 'does not raise error' do
        migrate!

        expect(Alerting::ProjectAlertingSetting.count).to eq(0)
      end
    end
  end
end
