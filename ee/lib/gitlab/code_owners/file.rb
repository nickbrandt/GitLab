# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class File
      def initialize(blob, project = nil)
        @blob = blob
        @project = project
      end

      def parsed_data
        @parsed_data ||= get_parsed_data
      end

      def empty?
        parsed_data.empty?
      end

      def entry_for_path(path)
        path = "/#{path}" unless path.start_with?('/')

        matching_pattern = parsed_data.keys.reverse.detect do |pattern|
          path_matches?(pattern, path)
        end

        parsed_data[matching_pattern].dup if matching_pattern
      end

      def path
        @blob&.path
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
        if Feature.enabled?(:sectional_codeowners, @project, default_enabled: false)
          return get_parsed_sectional_data
        end

        parsed = {}

        data.lines.each do |line|
          line = line.strip

          next if skip?(line)

          extract_entry_and_populate_parsed(line, parsed)
        end

        parsed
      end

      def get_parsed_sectional_data
        parsed = {}
        section = ::Gitlab::CodeOwners::Entry::DEFAULT_SECTION

        parsed[section] = {}

        data.lines.each do |line|
          line = line.strip

          next if skip?(line)

          if line.starts_with?('[') && line.end_with?(']')
            section = line[1...-1].strip
            parsed[section] ||= {}

            next
          end

          extract_entry_and_populate_parsed(line, parsed, section)
        end

        parsed
      end

      def extract_entry_and_populate_parsed(line, parsed, section = nil)
        pattern, _separator, owners = line.partition(/(?<!\\)\s+/)

        normalized_pattern = normalize_pattern(pattern)

        if section
          parsed[section][normalized_pattern] = Entry.new(pattern, owners, section)
        else
          parsed[normalized_pattern] = Entry.new(pattern, owners)
        end
      end

      def skip?(line)
        line.blank? || line.starts_with?('#')
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
        # `FNM_DOTMATCH` makes sure we also match files starting with a `.`
        # `FNM_PATHNAME` makes sure ** matches path separators
        flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME

        ::File.fnmatch?(pattern, path, flags)
      end
    end
  end
end
