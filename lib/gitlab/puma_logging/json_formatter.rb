# frozen_string_literal: true

require 'json'

module Gitlab
  module PumaLogging
    class JSONFormatter
      def call(str)
        {timestamp: Time.now.log_format, pid: $$, message: str }.to_json
      end
    end
  end
end
