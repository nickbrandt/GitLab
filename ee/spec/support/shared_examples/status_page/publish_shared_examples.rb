# frozen_string_literal: true

RSpec.shared_examples 'publish incidents' do
  before do
    stub_licensed_features(status_page: true)
  end

  context 'when upload succeeds' do
    before do
      allow(storage_client).to receive(:upload_object).with(key, content_json)
    end

    it 'publishes details as JSON' do
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
      allow(storage_client).to receive(:upload_object).with(key, content_json)
        .and_raise(exception)
    end

    it 'returns an error with exception' do
      expect(result).to be_error
      expect(result.message).to eq(exception.message)
      expect(result.payload).to eq(error: exception)
    end
  end

  context 'when limits exceeded' do
    let(:too_big) { 'a' * StatusPage::PublishBaseService::JSON_MAX_SIZE }

    before do
      if content.is_a?(Array)
        content.concat([too_big: too_big])
      else
        content.merge!(too_big: too_big)
      end
    end

    it 'returns limit exceeded error' do
      expect(result).to be_error
      expect(result.message).to eq(
        "Failed to upload #{key}: Limit exceeded"
      )
    end
  end

  context 'when feature is not available' do
    before do
      stub_licensed_features(status_page: false)
    end

    it 'returns feature not available error' do
      expect(result).to be_error
      expect(result.message).to eq('Feature not available')
    end
  end
end
