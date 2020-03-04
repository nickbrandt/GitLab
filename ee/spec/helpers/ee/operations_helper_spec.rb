# frozen_string_literal: true

require 'spec_helper'

describe OperationsHelper do
  describe '#status_page_settings_data' do
    subject { helper.status_page_settings_data(status_page_setting) }

    before do
      allow(helper).to receive(:can?) { true }
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

      it 'returns nil for the values' do
        expect(subject.values.uniq).to contain_exactly(nil)
      end
    end

    context 'setting exists' do
      let(:status_page_setting) { create(:status_page_setting) }

      it 'returns the correct values' do
        aggregate_failures do
          expect(subject['setting-enabled']).to eq(status_page_setting.enabled)
          expect(subject['setting-aws-access-key']).to eq(status_page_setting.aws_access_key)
          expect(subject['setting-masked-aws-secret-key']).to eq(status_page_setting.masked_aws_secret_key)
          expect(subject['setting-aws-region']).to eq(status_page_setting.aws_region)
          expect(subject['setting-aws-s3-bucket-name']).to eq(status_page_setting.aws_s3_bucket_name)
        end
      end
    end
  end
end
