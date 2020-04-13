# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishDetailsService do
  let_it_be(:project, refind: true) { create(:project) }
  let(:markdown_field) { "" }
  let(:user_notes) { [] }
  let(:issue) { instance_double(Issue, notes: user_notes, description: markdown_field) }
  let(:incident_id) { 1 }
  let(:key) { StatusPage::Storage.details_path(incident_id) }
  let(:content) { { id: incident_id } }

  let(:service) { described_class.new(project: project) }

  subject(:result) { service.execute(issue, user_notes) }

  describe '#execute' do
    before do
      allow(serializer).to receive(:represent_details).with(issue, user_notes)
        .and_return(content)
    end

    include_examples 'publish incidents'

    context 'when serialized content is missing id' do
      let(:content) { { other_id: incident_id } }

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to eq('Missing object key')
      end
    end

    context 'publishes images' do
      # no upload in markdown
      # s3 not avalible

      context 'when upload is in markdown' do
        let(:upload_secret) { '734b8524a16d44eb0ff28a2c2e4ff3c0' }
        let(:image_file_name) { 'tanuki.png'}
        let(:upload_path) { "/uploads/#{upload_secret}/#{image_file_name}" }
        let(:markdown_field) { "![tanuki](#{upload_path})" }
        let(:user_note) { instance_double(Note, note: markdown_field) }
        let(:user_notes) { [user_note] }
        let(:open_file) { instance_double(File) }
        let(:upload) { double(file: double(:file, file: upload_path)) }

        before do
          allow_next_instance_of(FileUploader) do |uploader|
            allow(uploader).to receive(:retrieve_from_store!).and_return(upload)
          end
          allow(File).to receive(:open).and_return(open_file)
          allow(storage_client).to receive(:upload_object)
          allow(storage_client).to receive(:upload_object).with(upload_path, open_file)
        end

        it 'publishes images in incident markdown' do
          expect(result).to be_success
          expect(result.payload).to have_key(:json_object_key)
          status_page_upload_path = StatusPage::Storage.upload_path(issue.id, upload_secret, image_file_name)
          expect(result.payload[:image_object_keys]).to eq([status_page_upload_path, status_page_upload_path])
        end
      end
    end
  end
end
