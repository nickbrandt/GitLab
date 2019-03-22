# frozen_string_literal: true
require 'spec_helper'

describe DependencyProxy::PullManifestService do
  include EE::DependencyProxyHelpers

  let(:image) { 'alpine' }
  let(:tag) { '3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:manifest) { { foo: 'bar' }.to_json }

  subject { described_class.new(image, tag, token) }

  before do
    stub_manifest_download(image, tag)
  end

  it 'downloads blob and writes it into the file' do
    expect(subject.execute).to eq(manifest)
  end
end
