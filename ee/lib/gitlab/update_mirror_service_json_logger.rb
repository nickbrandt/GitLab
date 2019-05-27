# frozen_string_literal: true

module Gitlab
  class UpdateMirrorServiceJsonLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'update_mirror_service_json'
    end
  end
end
