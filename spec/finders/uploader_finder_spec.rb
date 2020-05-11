# frozen_string_literal: true

require 'spec_helper'

describe UploaderFinder do
  describe '#execute' do
    let(:project) { build(:project) }
    let(:upload) { create(:upload, :issuable_upload, :with_file) }
    let(:secret) { upload.secret }
    let(:file_name) { upload.path }

    subject { described_class.new(project, secret, file_name).execute }

    before do
      upload.save
    end

    it 'gets the uploader' do
      allow_next_instance_of(FileUploader) do |uploader|
        expect(uploader).to receive(:retrieve_from_store!).with(upload.path).and_return(uploader)
      end
      expect(subject).to be_an_instance_of(FileUploader)
      expect(subject.model).to eq(project)
      expect(subject.secret).to eq(secret)
    end

    context 'path traversal in file name' do
      before do
        upload.path = '/uploads/11111111111111111111111111111111/../../../../../../../../../../../../../../etc/passwd)'
        upload.save
      end

      it 'throws an error' do
        expect { subject }.to raise_error(an_instance_of(StandardError).and(having_attributes(message: "Invalid path")))
      end
    end
  end
end
