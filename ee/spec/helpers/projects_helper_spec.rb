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

  describe 'default_clone_protocol' do
    context 'when gitlab.config.kerberos is enabled and user is logged in' do
      it 'returns krb5 as default protocol' do
        allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
        allow(helper).to receive(:current_user).and_return(double)

        expect(helper.send(:default_clone_protocol)).to eq('krb5')
      end
    end
  end
end
