# frozen_string_literal: true

require 'spec_helper'

describe OperationsHelper do
  describe '#status_page_settings_data' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private) }

    subject { helper.status_page_settings_data(status_page_setting) }

    before do
      helper.instance_variable_set(:@project, project)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper)
        .to receive(:can?).with(user, :admin_operations, project) { true }
    end

    context 'setting does not exist' do
      let(:status_page_setting) { nil }

      it 'returns the correct values' do
        expect(subject.keys)
          .to contain_exactly(
            'user-can-enable-status-page',
            'setting-enabled',
            'setting-aws-access-key',
            'setting-masked-aws-secret-key',
            'setting-aws-region',
            'setting-aws-s3-bucket-name'
          )
      end

      it 'returns nil or true for the values' do
        expect(subject.values.uniq).to contain_exactly('true', nil)
      end

      context 'user does not have permission' do
        before do
          allow(helper)
            .to receive(:can?).with(user, :admin_operations, project) { false }
        end

        it 'returns nil or true for the values' do
          expect(subject.values.uniq).to contain_exactly('false', nil)
        end
      end
    end

    context 'setting exists' do
      let(:status_page_setting) { create(:status_page_setting) }

      it 'returns the correct values' do
        aggregate_failures do
          expect(subject['user-can-enable-status-page']).to eq('true')
          expect(subject['setting-enabled']).to eq(status_page_setting.enabled.to_s)
          expect(subject['setting-aws-access-key']).to eq(status_page_setting.aws_access_key)
          expect(subject['setting-masked-aws-secret-key']).to eq(status_page_setting.masked_aws_secret_key)
          expect(subject['setting-aws-region']).to eq(status_page_setting.aws_region)
          expect(subject['setting-aws-s3-bucket-name']).to eq(status_page_setting.aws_s3_bucket_name)
        end
      end
    end
  end
end
