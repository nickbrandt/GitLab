# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Tracking
          class Source < Base
            attr_reader :file_path
            attr_reader :line_start
            attr_reader :line_end

            def initialize(file_path:, line_start:, line_end:)
              @file_path = file_path
              @line_start = line_start
              @line_end = line_end
            end

            private

            def fingerprint_data
              "#{file_path}:#{line_start}:#{line_end}"
            end
          end
        end
      end
    end
  end
end
