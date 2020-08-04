# frozen_string_literal: true

module Versions

  # this is an CarrierWave internal class, we are overriding blank_uploader so we could control which uploader is created.
  # it should be removed when feature flag :static_image_resizing is removed
  class Mounter < CarrierWave::Mounter #:nodoc:
    def blank_uploader
      record.class.avatar_uploader_class.new(record, column)
    end
  end
end
