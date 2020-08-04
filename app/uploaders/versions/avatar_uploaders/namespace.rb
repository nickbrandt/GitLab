# frozen_string_literal: true

module Versions
  module AvatarUploaders
    class Namespace < AvatarUploader
      include GitlabUploaderVersions

      AVATAR_SIZES = [15, 38, 64].freeze

      versions_for AVATAR_SIZES
    end
  end
end
