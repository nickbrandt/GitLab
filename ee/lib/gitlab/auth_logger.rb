# frozen_string_literal: true

module Gitlab
  class AuthLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'auth_json'
    end
  end
end
