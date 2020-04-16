# frozen_string_literal: true

require 'spec_helper'

describe OperationsHelper do
  describe '#status_page_settings_data' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:status_page_setting) { project.build_status_page_setting }

    subject { helper.status_page_settings_data }

    before do
      helper.instance_variable_set(:@project, project)
      allow(helper).to receive(:status_page_setting) { status_page_setting }
      allow(helper).to receive(:current_user) { user }
      allow(helper)
        .to receive(:can?).with(user, :admin_operations, project) { true }
    end

    context 'setting does not exist' do
      it 'returns the correct values' do
        expect(subject).to eq(
          'operations-settings-endpoint' => project_settings_operations_path(project),
          'enabled' => 'false',
          'aws-access-key' => nil,
          'aws-secret-key' => nil,
          'region' => nil,
          'bucket-name' => nil
        )
      end

      context 'user does not have permission' do
        before do
          allow(helper)
            .to receive(:can?).with(user, :admin_operations, project) { false }
        end

        it 'returns the correct values' do
          expect(subject).to eq(
            'operations-settings-endpoint' => project_settings_operations_path(project),
            'enabled' => 'false',
            'aws-access-key' => nil,
            'aws-secret-key' => nil,
            'region' => nil,
            'bucket-name' => nil
          )
        end
      end
    end

    context 'setting exists' do
      let(:status_page_setting) { create(:status_page_setting) }

      it 'returns the correct values' do
        expect(subject).to eq(
          'operations-settings-endpoint' => project_settings_operations_path(project),
          'enabled' => status_page_setting.enabled.to_s,
          'aws-access-key' => status_page_setting.aws_access_key,
          'aws-secret-key' => status_page_setting.masked_aws_secret_key,
          'region' => status_page_setting.aws_region,
          'bucket-name' => status_page_setting.aws_s3_bucket_name
        )
      end
    end
  end
end
