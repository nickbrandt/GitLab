# frozen_string_literal: true
module EE
  module StubObjectStorage
    def stub_packages_object_storage(**params)
      stub_object_storage_uploader(config: ::Gitlab.config.packages.object_store,
                                   uploader: ::Packages::PackageFileUploader,
                                   remote_directory: 'packages',
                                   **params)
    end

    def stub_dependency_proxy_object_storage(**params)
      stub_object_storage_uploader(config: ::Gitlab.config.dependency_proxy.object_store,
                                   uploader: ::DependencyProxy::FileUploader,
                                   remote_directory: 'dependency_proxy',
                                   **params)
    end

    def stub_object_storage_pseudonymizer
      stub_object_storage(connection_params: Pseudonymizer::Uploader.object_store_credentials,
                          remote_directory: Pseudonymizer::Uploader.remote_directory)
    end
  end
end
