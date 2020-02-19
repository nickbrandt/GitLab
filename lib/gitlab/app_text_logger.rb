# frozen_string_literal: true

module Gitlab
  class AppTextLogger < Gitlab::Logger
    def self.file_name_noext
      'application'
    end

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.log_format}: #{msg}\n"
    end
  end
end
