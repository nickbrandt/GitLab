# frozen_string_literal: true

module Versions
  module GitlabUploaderVersions
    extend ActiveSupport::Concern
    include CarrierWave::MiniMagick
    include CarrierWave::Uploader::Processing
    include CarrierWave::Uploader::Versions
    include Gitlab::TemporarilyAllow

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

    def find_or_create_version(size)
      return unless size

      version_type = self.class.version_name_for(size).to_sym

      return unless version_exists?(version_type)

      version = versions[version_type]

      if version && version.file.exists?
        version
      else
        # If version is not found, recreate versions in the background
        enqueue_recreate_versions_job
      end
    end

    def recreate_versions_async!
      temporarily_allow(process_async_key) do
        recreate_versions!
      end
    end

    def allowed?(file)
      (file.present? || process_async?)
    end

    def process_async?
      temporarily_allowed?(process_async_key)
    end

    def enqueue_recreate_versions_job
      return unless upload

      CarrierWave::RecreateVersionsWorker.perform_async(model.class.to_s,
                                                        mounted_as,
                                                        model.id)
    end

    private

    def process_async_key
      "#{model.class.name}:#{model.id}:#{mounted_as}:process_async"
    end
  end
end
