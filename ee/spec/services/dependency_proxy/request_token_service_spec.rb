# frozen_string_literal: true
require 'spec_helper'

describe DependencyProxy::RequestTokenService do
  include EE::DependencyProxyHelpers

  let(:image) { 'alpine:3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }

  subject { described_class.new(image).execute }

  before do
    stub_registry_auth(image, token)
  end

  it 'requests an access token from auth service' do
    is_expected.to eq(token)
  end
end
