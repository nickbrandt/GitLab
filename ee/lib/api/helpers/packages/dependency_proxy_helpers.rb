# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module DependencyProxyHelpers
        REGISTRY_BASE_URLS = {
          npm: 'https://registry.npmjs.org/'
        }.freeze

        def proxy_registry_request(check_registry, package_type, options)
          if check_registry # TODO add application setting + feature flag check here
            send_registry_request(registry_url(package_type, options))
          else
            raise ArgumentError, "You can't call #proxy_request without a block" unless block_given?

            yield
          end
        end

        def redirect_registry_request(check_registry, package_type, options)
          if check_registry
            redirect(registry_url(package_type, options))
          else
            raise ArgumentError, "You can't call #redirect_request without a block" unless block_given?

            yield
          end
        end

        def send_registry_request(registry_url)
          result = DependencyProxy::Packages::ProxyService.new(registry_url).execute

          if result[:status] == :error
            status result[:http_status]
          else
            response = result[:response]
            status response.code
            content_type response.headers['content-type']
            file result[:file].path
          end
        end

        def registry_url(package_type, options)
          base_url = REGISTRY_BASE_URLS[package_type]

          raise ArgumentError, "Can't proxy requests for packages of type #{package_type}" unless base_url

          case package_type
          when :npm
            "#{base_url}#{options[:package_name]}"
          end
        end
      end
    end
  end
end
