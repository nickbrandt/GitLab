# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Replication::FileDownloader, :geo do
  include EE::GeoHelpers

  let_it_be(:primary_node) { create(:geo_node, :primary) }

  subject { downloader.execute }

  let(:upload) { create(:upload, :issuable_upload, :with_file) }
  let(:downloader) { described_class.new(:file, upload.id) }

  context 'when in primary geo node' do
    before do
      stub_current_geo_node(primary_node)
    end

    it 'fails to download the file' do
      expect(subject.success).to be_falsey
      expect(subject.primary_missing_file).to be_falsey
    end
  end

  context 'when in a secondary geo node' do
    context 'with local storage only' do
      let(:secondary_node) { create(:geo_node, :local_storage_only) }

      before do
        stub_current_geo_node(secondary_node)

        stub_geo_file_transfer(:file, upload)
      end

      it 'downloads the file' do
        expect(subject.success).to be_truthy
        expect(subject.primary_missing_file).to be_falsey
      end
    end
  end

  def stub_geo_file_transfer(file_type, upload)
    url = primary_node.geo_transfers_url(file_type, upload.id.to_s)

    stub_request(:get, url).to_return(status: 200, body: upload.retrieve_uploader.file.read, headers: {})
  end

  def stub_geo_file_transfer_object_storage(file_type, upload)
    url = primary_node.geo_transfers_url(file_type, upload.id.to_s)

    stub_request(:get, url).to_return(status: 307, body: upload.retrieve_uploader.url, headers: {})
  end
end
