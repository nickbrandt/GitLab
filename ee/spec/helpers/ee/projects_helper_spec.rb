# frozen_string_literal: true

require 'spec_helper'

describe ProjectsHelper do
  describe '#project_incident_management_setting' do
    set(:project) { create(:project) }

    before do
      helper.instance_variable_set(:@project, project)
    end

    context 'when incident_management_setting exists' do
      let(:project_incident_management_setting) do
        create(:project_incident_management_setting, project: project)
      end

      it 'return project_incident_management_setting' do
        expect(helper.project_incident_management_setting).to(
          eq(project_incident_management_setting)
        )
      end
    end

    context 'when incident_management_setting does not exist' do
      it 'builds incident_management_setting' do
        expect(helper.project_incident_management_setting.persisted?).to be(false)

        expect(helper.project_incident_management_setting.send_email).to be(true)
        expect(helper.project_incident_management_setting.create_issue).to be(false)
        expect(helper.project_incident_management_setting.issue_template_key).to be(nil)
      end
    end
  end
end
