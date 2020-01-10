# frozen_string_literal: true

module DesignManagement
  # This service generates smaller image versions for `DesignManagement::Design`
  # records within a given `DesignManagement::Version`.
  class GenerateImageVersionsService < DesignService
    def initialize(version, sizes: all_sizes)
      super(version.project, version.author, issue: version.issue)

      @version = version
      @sizes = Array.wrap(sizes)
    end

    def execute
      validate_sizes!

      # rubocop: disable CodeReuse/ActiveRecord
      version.actions.includes(:design).each do |action|
        generate_images(action)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      success(version: version)
    end

    private

    attr_reader :version, :sizes

    def all_sizes
      @all_sizes ||= DesignManagement::DesignUploader.versions.keys
    end

    def validate_sizes!
      invalid_sizes = sizes - all_sizes

      if invalid_sizes.present?
        raise ArgumentError, "Invalid sizes: #{invalid_sizes.to_sentence}"
      end
    end

    def generate_images(action)
      # Some images, like SVGs, are never resized
      return unless DesignManagement::DesignUploader.resize?(action.design.filename)

      raw_file = get_raw_file(action)

      unless raw_file
        log_error("No design file found for Action: #{action.id}")
        return
      end

      ActiveRecord::Base.transaction do
        action.file.cache!(raw_file) # Cache in order to process the image
        action.file.recreate_versions!(*sizes)
        action.save! # link the record and uploader
        action.file.record_upload
      end
    rescue StandardError => e
      log_error(e.message)
    end

    # Returns the `CarrierWave::SanitizedFile` of the original design file
    def get_raw_file(action)
      raw_files_by_path[action.design.full_path]
    end

    # Returns the `Carrierwave:SanitizedFile` instances for all of the original
    # design files, mapping to { design.filename => `Carrierwave::SanitizedFile` }.
    #
    # As design files are stored in Git LFS, the only way to retrieve their original
    # files is to first fetch the LFS pointer file data from the Git design repository.
    # The LFS pointer file data contains an "OID" that lets us retrieve  `LfsObject`
    # records, which have an Uploader (`LfsObjectUploader`) for the original design file.
    def raw_files_by_path
      @raw_files_by_path ||= begin
        # Load `Blob`s (these are Lfs Pointer files, and are small amounts of data)
        items = version.designs.map { |d| [version.sha, d.full_path] }
        blobs = repository.blobs_at(items)

        # Use the `Blob`s to fetch the corresponding `LfsObject`s
        LfsObject.for_oids(blobs.map(&:lfs_oid)).each_with_object({}) do |lfs_object, h|
          blob = blobs.find { |b| b.lfs_oid == lfs_object.oid }
          h[blob.path] = lfs_object.file.file
        end
      end
    end
  end
end
