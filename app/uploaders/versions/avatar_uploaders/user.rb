# frozen_string_literal: true

module Versions
  module AvatarUploaders
    class User < AvatarUploader
      include GitlabUploaderVersions

      AVATAR_SIZES = [40, 24, 23, 20, 16, 26].freeze

      versions_for AVATAR_SIZES
    end
  end
end
