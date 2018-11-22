# frozen_string_literal: true

module Gitlab
  class ReturnToLocation
    include ::Gitlab::Utils::StrongMemoize

    def initialize(location)
      @location = location
    end

    def full_path
      strong_memoize(:full_path) do
        uri = parse_uri

        if uri
          path = remove_domain_from_uri(uri)
          path = add_fragment_back_to_path(uri, path)
          path
        end
      end
    end

    private

    attr_reader :location

    def parse_uri
      location && URI.parse(location.sub(%r{\A\/\/+}, '/'))
    rescue URI::InvalidURIError
      nil
    end

    def remove_domain_from_uri(uri)
      [uri.path.sub(%r{\A\/+}, '/'), uri.query].compact.join('?')
    end

    def add_fragment_back_to_path(uri, path)
      [path, uri.fragment].compact.join('#')
    end
  end
end
