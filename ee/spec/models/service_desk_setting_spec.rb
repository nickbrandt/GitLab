# frozen_string_literal: true

require 'spec_helper'

describe ServiceDeskSetting do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_length_of(:outgoing_name).is_at_most(255) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe '.update_template_key_for' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    context 'when template exists' do
      it 'updates issue_template_key' do
        template_path = '.gitlab/issue_templates/service_desk.md'
        project.repository.create_file(user, template_path, 'Template text', message: 'message', branch_name: 'master')

        described_class.update_template_key_for(project: project, issue_template_key: 'service_desk')

        expect(project.service_desk_setting.issue_template_key).to eq('service_desk')
      end
    end

    context 'when template does not exist' do
      it 'raises error' do
        expect do
          described_class.update_template_key_for(project: project, issue_template_key: 'unknown')
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
