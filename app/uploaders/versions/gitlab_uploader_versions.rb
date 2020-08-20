# frozen_string_literal: true

module Versions
  module GitlabUploaderVersions
    extend ActiveSupport::Concern
    include CarrierWave::MiniMagick
    include CarrierWave::Uploader::Processing
    include CarrierWave::Uploader::Versions
    include Gitlab::TemporarilyAllow

    included do
      after :object_store_change, :change_versions_object_store!
    end

    SIZE_PATTERN = "w%d".freeze

    class_methods do
      def version_name_for(size)
        (SIZE_PATTERN % size)
      end

      ##
      # Generate versions for provided sizes to this uploader
      #
      # === Parameters
      #
      # [sizes (#Array)] Integer array of supported sizes
      #
      # === Examples
      #
      #     class MyUploader < CarrierWave::Uploader::Base
      #
      #       versions_for [16, 32, 40]
      #
      #     end
      #
      def versions_for(sizes)
        sizes.each do |size|
          version version_name_for(size), if: :allowed? do
            process resize_to_fit: [size, nil]
          end
        end
      end
    end

    ##
    # Finds the correct uploader version with the given size, or schedule version recreation and returns original uploader.
    #
    # === Parameters
    #
    # [size (#Integer)] Version size
    #
    # === Returns
    #
    # [GitlabUploader] Returns version uploader or the original one.
    #
    def find_or_create_version(size)
      return unless size

      version_type = self.class.version_name_for(size).to_sym
      # fallback to the original uploader if size is not supported
      return self unless version_exists?(version_type)

      version = versions[version_type]

      if version && version.file.exists?
        version
      else
        # If version is not found, recreate versions in the background
        enqueue_recreate_versions_job
        # fallback to the original uploader if version is not found
        self
      end
    end

    def recreate_versions_async!
      with_allow_versions do
        recreate_versions!
      end
    end

    def unsafe_migrate!(new_store)
      with_allow_versions do
        super
      end
    end

    def allowed?(file)
      file.present? || process_async?
    end

    def process_async?
      temporarily_allowed?(process_async_key)
    end

    def schedule_background_recreate
      return if self.class.background_upload_enabled?

      enqueue_recreate_versions_job
    end

    private

    def with_allow_versions
      temporarily_allow(process_async_key) do
        yield
      end
    end

    def enqueue_recreate_versions_job
      CarrierWave::RecreateVersionsWorker.perform_async(model.class.to_s,
                                                        mounted_as,
                                                        model.id)
    end

    def change_versions_object_store!(new_store)
      active_versions.each { |name, v| v.object_store = new_store }
    end

    def process_async_key
      "#{model.class.name}:#{model.id}:#{mounted_as}:process_async"
    end
  end
end
