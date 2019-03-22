# frozen_string_literal: true
require 'spec_helper'

describe DependencyProxy::FindOrCreateBlobService do
  include EE::DependencyProxyHelpers

  let(:blob)  { create(:dependency_proxy_blob) }
  let(:group) { blob.group }
  let(:image) { 'alpine' }
  let(:tag)   { '3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:blob_sha) { '40bd001563085fc35165329ea1ff5c5ecbdbbeef' }

  subject { described_class.new(group, image, token, blob_sha).execute }

  before do
    stub_registry_auth(image, token)
  end

  context 'no cache' do
    before do
      stub_blob_download(image, blob_sha)
    end

    it 'downloads blob from remote registry if there is no cached one' do
      is_expected.to be_a(DependencyProxy::Blob)
      is_expected.to be_persisted
    end
  end

  context 'cached blob' do
    let(:blob_sha) { blob.file_name.sub('.gz', '') }

    it 'uses cached blob instead of downloading one' do
      is_expected.to be_a(DependencyProxy::Blob)
      is_expected.to eq(blob)
    end
  end

  context 'no such blob exists remotely' do
    before do
      stub_blob_download_not_found(image, blob_sha)
    end

    it { is_expected.to be nil }
  end
end
