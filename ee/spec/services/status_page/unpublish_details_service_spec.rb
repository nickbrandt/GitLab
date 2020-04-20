# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::UnpublishDetailsService do
  let_it_be(:project, refind: true) { create(:project) }
  let(:issue) { instance_double(Issue, iid: incident_id) }
  let(:incident_id) { 1 }
  let(:key) { StatusPage::Storage.details_path(incident_id) }

  let(:service) { described_class.new(project: project) }

  subject(:result) { service.execute(issue) }

  describe '#execute' do
    let(:status_page_setting_enabled) { true }
    let(:storage_client) { instance_double(StatusPage::Storage::S3Client) }

    let(:status_page_setting) do
      instance_double(StatusPage::ProjectSetting, enabled?: status_page_setting_enabled,
                      storage_client: storage_client)
    end

    before do
      stub_licensed_features(status_page: true)

      allow(project).to receive(:status_page_setting)
        .and_return(status_page_setting)
    end

    context 'when deletion succeeds' do
      before do
        allow(storage_client).to receive(:delete_object).with(key)
      end

      it 'removes details from CDN' do
        expect(result).to be_success
        expect(result.payload).to eq(object_key: key)
      end
    end

    context 'when upload fails due to exception' do
      let(:bucket) { 'bucket_name' }
      let(:error) { StandardError.new }

      let(:exception) do
        StatusPage::Storage::Error.new(bucket: bucket, error: error)
      end

      before do
        allow(storage_client).to receive(:delete_object).with(key)
          .and_raise(exception)
      end

      it 'propagates the exception' do
        expect { result }.to raise_error(exception)
      end
    end

    context 'when status page setting is not enabled' do
      let(:status_page_setting_enabled) { false }

      it 'returns feature not available error' do
        expect(result).to be_error
        expect(result.message).to eq('Feature not available')
      end
    end
  end
end
