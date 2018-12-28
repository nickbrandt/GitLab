# frozen_string_literal: true
module EE
  module StubObjectStorage
    def stub_packages_object_storage(**params)
      stub_object_storage_uploader(config: ::Gitlab.config.packages.object_store,
                                   uploader: ::Packages::PackageFileUploader,
                                   remote_directory: 'packages',
                                   **params)
    end
  end
end
