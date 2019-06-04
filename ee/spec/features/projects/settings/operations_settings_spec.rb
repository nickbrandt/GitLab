# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Settings' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, create_templates: :issue) }
  let(:role) { :maintainer }
  let(:create_issue) { 'Create an issue. Issues are created for each alert triggered.' }
  let(:send_email) { 'Send a separate email notification to Developers.' }

  before do
    create(:project_incident_management_setting, send_email: true, project: project)
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'Incidents' do
    context 'with license' do
      before do
        stub_licensed_features(incident_management: true)
        visit project_settings_operations_path(project)
      end

      it 'renders form for incident management' do
        expect(page).to have_selector('h4', text: 'Incidents')
      end

      it 'sets correct default values' do
        expect(find_field(create_issue)).not_to be_checked
        expect(find_field(send_email)).to be_checked
      end

      it 'updates form values' do
        check(create_issue)
        template_select = find_field('Issue template')
        template_select.find(:xpath, 'option[2]').select_option
        uncheck(send_email)
        save_form

        expect(find_field(create_issue)).to be_checked
        expect(page).to have_select('Issue template', selected: 'bug')
        expect(find_field(send_email)).not_to be_checked
      end

      def save_form
        page.within "#edit_project_#{project.id}" do
          click_on 'Save changes'
        end
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(incident_management: false)
        visit project_settings_operations_path(project)
      end

      it 'renders form for incident management' do
        expect(page).not_to have_selector('h4', text: 'Incidents')
      end
    end
  end
end
