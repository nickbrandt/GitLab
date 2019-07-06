# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Geo::FileDownloader, :geo do
  include EE::GeoHelpers

  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }

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
    before do
      stub_current_geo_node(secondary_node)

      stub_geo_file_transfer(:file, upload)
    end

    it 'downloads the file' do
      expect(subject.success).to be_truthy
      expect(subject.primary_missing_file).to be_falsey
    end
  end

  def stub_geo_file_transfer(file_type, upload)
    url = primary_node.geo_transfers_url(file_type, upload.id.to_s)

    stub_request(:get, url).to_return(status: 200, body: upload.build_uploader.file.read, headers: {})
  end
end
