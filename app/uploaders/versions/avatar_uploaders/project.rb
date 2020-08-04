# frozen_string_literal: true

module Versions
  module AvatarUploaders
    class Project < AvatarUploader
      include GitlabUploaderVersions

      AVATAR_SIZES = [48, 15, 40, 64].freeze

      versions_for AVATAR_SIZES
    end
  end
end

