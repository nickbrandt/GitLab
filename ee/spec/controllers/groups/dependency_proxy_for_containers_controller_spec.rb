# frozen_string_literal: true

require 'spec_helper'

describe Groups::DependencyProxyForContainersController do
  let(:group) { create(:group) }

  before do
    allow(Gitlab.config.dependency_proxy)
      .to receive(:enabled).and_return(true)

    allow_any_instance_of(DependencyProxy::RequestTokenService)
      .to receive(:execute).and_return('abcd1234')
  end

  describe 'GET #manifest' do
    let(:manifest) { { foo: 'bar' }.to_json }

    before do
      allow_any_instance_of(DependencyProxy::PullManifestService)
        .to receive(:execute).and_return(manifest)
    end

    it 'returns 200 with manifest file' do
      enable_dependency_proxy

      get_manifest

      expect(response).to have_gitlab_http_status(200)
      expect(response.body).to eq(manifest)
    end

    it 'returns 404 when feature is disabled' do
      get_manifest

      expect(response).to have_gitlab_http_status(404)
    end

    def get_manifest
      get :manifest, params: { group_id: group.to_param, image: 'alpine', tag: '3.9.2' }
    end
  end

  describe 'GET #blob' do
    let(:blob) { create(:dependency_proxy_blob) }
    let(:blob_sha) { blob.file_name.sub('.gz', '') }

    before do
      allow_any_instance_of(DependencyProxy::FindOrCreateBlobService)
        .to receive(:execute).and_return(blob)
    end

    context 'feature enabled' do
      before do
        enable_dependency_proxy
      end

      it 'sends a file' do
        expect(controller).to receive(:send_file).with(blob.file.path, {})

        get_blob
      end

      it 'returns Content-Disposition: attachment' do
        get_blob

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Disposition']).to match(/^attachment/)
      end
    end

    it 'returns 404 when feature is disabled' do
      get_blob

      expect(response).to have_gitlab_http_status(404)
    end

    def get_blob
      get :blob, params: { group_id: group.to_param, image: 'alpine', sha: blob_sha }
    end
  end

  def enable_dependency_proxy
    stub_licensed_features(dependency_proxy: true)
    group.create_dependency_proxy_setting!(enabled: true)
  end
end
