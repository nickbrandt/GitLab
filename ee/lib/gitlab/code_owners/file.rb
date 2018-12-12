# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class File
      def initialize(blob)
        @blob = blob
      end

      def parsed_data
        @parsed_data ||= get_parsed_data
      end

      def empty?
        parsed_data.empty?
      end

      def owners_for_path(path)
        path = "/#{path}" unless path.start_with?('/')

        matching_pattern = parsed_data.keys.reverse.detect do |pattern|
          path_matches?(pattern, path)
        end

        parsed_data[matching_pattern]
      end

      private

      def data
        if @blob && !@blob.binary?
          @blob.data
        else
          ""
        end
      end

      def get_parsed_data
        parsed = {}

        data.lines.each do |line|
          line = line.strip
          next unless line.present?
          next if line.starts_with?('#')

          pattern, _separator, owners = line.partition(/(?<!\\)\s+/)

          pattern = normalize_pattern(pattern)

          parsed[pattern] = owners
        end

        parsed
      end

      def normalize_pattern(pattern)
        # Remove `\` when escaping `\#`
        pattern = pattern.sub(/\A\\#/, '#')
        # Replace all whitespace preceded by a \ with a regular whitespace
        pattern = pattern.gsub(/\\\s+/, ' ')

        return '/**/*' if pattern == '*'

        unless pattern.starts_with?('/')
          pattern = "/**/#{pattern}"
        end

        if pattern.end_with?('/')
          pattern = "#{pattern}**/*"
        end

        pattern
      end

      def path_matches?(pattern, path)
        flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME

        # Then the pattern ends in a wildcard, we only want to go one level deep
        # setting `::File::FNM_PATHNAME` makes the `*` not match directory
        # separators
        ::File.fnmatch?(pattern, path, flags)
      end
    end
  end
end
