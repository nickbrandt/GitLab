module EE
  module DependencyProxyHelpers
    def stub_registry_auth(image, token)
      auth_body = { 'token' => token }.to_json
      auth_link = registry.auth_url(image)

      stub_request(:get, auth_link)
        .to_return(status: 200, body: auth_body)
    end

    def stub_manifest_download(image, tag)
      manifest_url = registry.manifest_url(image, tag)

      stub_request(:get, manifest_url)
        .to_return(status: 200, body: manifest)
    end

    def stub_blob_download(image, blob_sha)
      download_link = registry.blob_url(image, blob_sha)

      stub_request(:get, download_link)
        .to_return(status: 200, body: '123456')
    end

    def stub_blob_download_not_found(image, blob_sha)
      download_link = registry.blob_url(image, blob_sha)

      stub_request(:get, download_link)
        .to_return(status: 404)
    end

    private

    def registry
      @registry ||= DependencyProxy::Registry
    end
  end
end
