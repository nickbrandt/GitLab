# frozen_string_literal: true
require 'spec_helper'

describe DependencyProxy::DownloadBlobService do
  include EE::DependencyProxyHelpers

  let(:image) { 'alpine' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:blob_sha) { Digest::SHA256.hexdigest('ruby:2.3.9') }
  let(:file) { Tempfile.new }

  subject { described_class.new(image, blob_sha, token, file.path) }

  before do
    stub_blob_download(image, blob_sha)
  end

  it 'downloads blob and writes it into the file' do
    expect { subject.execute }.to change { file.size }.from(0).to(6)
  end
end
