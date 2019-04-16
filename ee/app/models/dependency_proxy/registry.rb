# frozen_string_literal: true

class DependencyProxy::Registry
  AUTH_URL = 'https://auth.docker.io'.freeze
  LIBRARY_URL = 'https://registry-1.docker.io/v2/library'.freeze

  class << self
    def auth_url(image)
      "#{AUTH_URL}/token?service=registry.docker.io&scope=repository:library/#{image}:pull"
    end

    def manifest_url(image, tag)
      "#{LIBRARY_URL}/#{image}/manifests/#{tag}"
    end

    def blob_url(image, blob_sha)
      "#{LIBRARY_URL}/#{image}/blobs/#{blob_sha}"
    end
  end
end
