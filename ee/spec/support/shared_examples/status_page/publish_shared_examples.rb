# frozen_string_literal: true

RSpec.shared_examples 'publish incidents' do
  let(:status_page_setting_enabled) { true }
  let(:storage_client) { instance_double(StatusPage::Storage::S3Client) }
  let(:serializer) { instance_double(StatusPage::IncidentSerializer) }
  let(:content_json) { content.to_json }

  let(:status_page_setting) do
    instance_double(StatusPage::ProjectSetting, enabled?: status_page_setting_enabled,
                    storage_client: storage_client)
  end

  before do
    stub_licensed_features(status_page: true)

    allow(project).to receive(:status_page_setting)
      .and_return(status_page_setting)
    allow(StatusPage::IncidentSerializer).to receive(:new)
      .and_return(serializer)
  end

  context 'when json upload succeeds' do
    before do
      allow(storage_client).to receive(:upload_object).with(key, content_json)
      allow(storage_client).to receive(:list_object_keys).and_return(Set.new)
    end

    it 'publishes details as JSON' do
      expect(result).to be_success
      expect(storage_client).to receive(:upload_object).with(key, content_json)
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

    it 'propagates the exception' do
      expect { result }.to raise_error(exception)
    end
  end

  context 'when limits exceeded' do
    let(:too_big) { 'a' * StatusPage::Storage::JSON_MAX_SIZE }

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

  context 'when status page setting is not enabled' do
    let(:status_page_setting_enabled) { false }

    it 'returns feature not available error' do
      expect(result).to be_error
      expect(result.message).to eq('Feature not available')
    end
  end

  context 'publishes image uploads' do
    before do
      allow(storage_client).to receive(:upload_object).with("data/incident/1.json", "{\"id\":1}")
      allow(storage_client).to receive(:list_object_keys).and_return(Set.new)
    end

    context 'no upload in markdown' do
      it 'publishes no images' do
        expect(result).to be_success
        expect(result.payload[:image_object_keys]).to eq([])
      end
    end

    context 'upload in markdown' do
      let(:upload_secret) { '734b8524a16d44eb0ff28a2c2e4ff3c0' }
      let(:image_file_name) { 'tanuki.png'}
      let(:upload_path) { "/uploads/#{upload_secret}/#{image_file_name}" }
      let(:markdown_field) { "![tanuki](#{upload_path})" }
      let(:status_page_upload_path) { StatusPage::Storage.upload_path(issue.iid, upload_secret, image_file_name) }

      let(:open_file) { instance_double(File) }
      let(:upload) { double(file: double(:file, file: upload_path)) }

      before do
        allow_next_instance_of(FileUploader) do |uploader|
          allow(uploader).to receive(:retrieve_from_store!).and_return(upload)
        end
        allow(File).to receive(:open).and_return(open_file)
        allow(storage_client).to receive(:upload_object).with(upload_path, open_file)
      end

      it 'publishes description images' do
        expect(result).to be_success
        expect(result.payload[:image_object_keys]).to eq([status_page_upload_path])
      end

      context 'user notes uploads' do
        let(:user_note) { instance_double(Note, note: markdown_field) }
        let(:user_notes) { [user_note] }

        it 'publishes images' do
          expect(result).to be_success
          expect(result.payload[:image_object_keys]).to eq([status_page_upload_path])
        end
      end

      context 'when all images are in s3' do
        before do
          allow(storage_client).to receive(:list_object_keys).and_return(Set[status_page_upload_path])
        end

        it 'publishes no images' do
          expect(result).to be_success
          expect(result.payload[:image_object_keys]).to eq([])
        end
      end

      context 'when images are already in s3' do
        let(:upload_secret_2) { '9cb61a79ce884d5b6c1dd42728d3c159' }
        let(:image_file_name_2) { 'tanuki_2.png' }
        let(:upload_path_2) { "/uploads/#{upload_secret_2}/#{image_file_name_2}" }
        let(:markdown_field) { "![tanuki](#{upload_path}) and ![tanuki_2](#{upload_path_2})" }
        let(:status_page_upload_path_2) { StatusPage::Storage.upload_path(issue.iid, upload_secret_2, image_file_name_2) }

        before do
          allow(storage_client).to receive(:list_object_keys).and_return(Set[status_page_upload_path])
        end

        it 'publishes new images' do
          expect(result).to be_success
          expect(result.payload[:image_object_keys]).to eq([status_page_upload_path_2, status_page_upload_path_2])
        end
      end
    end
  end
end
