# frozen_string_literal: true

# This wraps calls to a gem which support mime type detection.
# Currently uses `mimemagic`, but that will be replaced shortly.
module Gitlab
  module Utils
    class MimeType
      class << self
        def from_io(io)
          return unless io.is_a?(IO) || io.is_a?(StringIO)

          MimeMagic.by_magic(io).try(:type)
        end

        def from_string(string)
          return unless string.is_a?(String)

          MimeMagic.by_magic(string)
        end
      end
    end
  end
end
