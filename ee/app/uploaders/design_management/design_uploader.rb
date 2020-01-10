# frozen_string_literal: true

module DesignManagement
  # This Uploader is used to generate and serve the smaller versions of
  # the design files.
  #
  # The original (full-sized) design files are stored in Git LFS, and so
  # have a different uploader, `LfsObjectUploader`.
  class DesignUploader < GitlabUploader
    include CarrierWave::MiniMagick
    include RecordsUploads::Concern
    include ObjectStorage::Concern
    prepend ObjectStorage::Extension::RecordsUploads

    # SVG files cannot be resized
    SKIP_EXTENSIONS = %w[svg].freeze

    version :v432x230, if: :resize? do
      process resize_to_fit: [432, 230]
    end

    def self.resize?(filename)
      return false unless filename

      !Gitlab::FileTypeDetection.extension_match?(filename, SKIP_EXTENSIONS)
    end

    # Set `#move_to_cache` to false, otherwise the `LfsObject` file
    # would be deleted.
    # https://github.com/carrierwaveuploader/carrierwave/blob/f84672a/lib/carrierwave/uploader/cache.rb#L131-L135
    def move_to_cache
      false
    end

    # Only store the file when called on an instance of the uploader that
    # represents the smaller image version, and never the original (full-size)
    # image. This prevents the accidental double-storing of the original design files,
    # as they already exist in the storage used by Git LFS.
    def store!(new_file = nil)
      return unless parent_version

      super(new_file)
    end

    private

    def resize?(_file)
      self.class.resize?(model.design&.filename)
    end

    def dynamic_segment
      File.join(model.class.underscore, mounted_as.to_s, model.id.to_s)
    end
  end
end
