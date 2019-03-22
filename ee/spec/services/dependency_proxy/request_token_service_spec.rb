# frozen_string_literal: true
require 'spec_helper'

describe DependencyProxy::RequestTokenService do
  let(:image) { 'alpine:3.9' }
  let(:token) { Digest::SHA256.hexdigest('123') }
  let(:registry) { DependencyProxy::Registry.new }

  subject { described_class.new(image).execute }

  before do
    auth_body = { 'token' => token }.to_json
    auth_link = registry.auth_url(image)

    stub_request(:get, auth_link)
      .to_return(status: 200, body: auth_body)
  end

  it 'requests an access token from auth service' do
    is_expected.to eq(token)
  end
end
