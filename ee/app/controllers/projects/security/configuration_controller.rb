# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      def index
        # TODO - remove this - it's only temp
        features = [
            {
                name: 'Static Application Security Testing (SAST)',
                description: 'Analyze your source code for known vulnerabilities',
                link: 'http://example.com',
                configured: true,
            },
            {
                name: 'Dynamic Application Security Testing (DAST)',
                description: 'Analyze a review version of your web application',
                link: 'http://example.com',
                configured: false,
            },
            {
                name: 'Container Scanning',
                description: 'Check your Docker images for known vulnerabilities',
                link: 'http://example.com',
                configured: false,
            },
            {
                name: 'Dependency Scanning',
                description: 'Analyze your dependencies for known vulnerabilities',
                link: 'http://example.com',
                configured: true,
            },
            {
                name: 'License Compliance',
                description: 'Search your project dependencies for their licenses and apply policies',
                link: 'http://example.com',
                configured: true,
            },
        ]

        @features = features.to_json
      end
    end
  end
end
