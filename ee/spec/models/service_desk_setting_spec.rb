# frozen_string_literal: true

require 'spec_helper'

describe ServiceDeskSetting do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_length_of(:outgoing_name).is_at_most(255) }

    describe '.valid_issue_template' do
      let_it_be(:project) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/service_desk.md' => 'template' }) }

      it 'is not valid if template does not exist' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'invalid key')

        expect(settings).not_to be_valid
        expect(settings.errors[:issue_template_key].first).to eq('is empty or does not exist')
      end

      it 'is valid if template exists' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'service_desk')

        expect(settings).to be_valid
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end
end
