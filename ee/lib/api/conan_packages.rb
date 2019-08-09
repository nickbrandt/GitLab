# frozen_string_literal: true
module API
  class ConanPackages < Grape::API
    before do
      not_found! unless Feature.enabled?(:conan_package_registry)
    end

    helpers ::API::Helpers::PackagesHelpers

    before do
      require_packages_enabled!
      require_conan_authentication!
    end

    desc 'Ping the Conan API' do
      detail 'This feature was introduced in GitLab 12.2'
    end
    get 'packages/conan/v1/ping' do
      nil
    end
  end
end
