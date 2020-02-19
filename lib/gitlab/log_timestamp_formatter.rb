# frozen_string_literal: true

module Gitlab
  class LogTimestampFormatter < Logger::Formatter
    FORMAT = "%s, [%s #%d] %5s -- %s: %s\n"

    def call(severity, timestamp, program_name, message)
      FORMAT % [severity[0..0], timestamp.log_format, $$, severity, program_name, msg2str(message)]
    end
  end
end
