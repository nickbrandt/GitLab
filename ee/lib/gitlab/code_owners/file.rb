# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class File
      include ::Gitlab::Utils::StrongMemoize

      SECTION_HEADER_REGEX = /\[(.*?)\]/.freeze

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

        if sectional_codeowners?
          sectional_entry_for_path(path)
        else
          non_sectional_entry_for_path(path)
        end
      end

      def path
        @blob&.path
      end

      private

      def non_sectional_entry_for_path(path)
        matching_pattern = parsed_data.keys.reverse.detect do |pattern|
          path_matches?(pattern, path)
        end

        matching_pattern ? [parsed_data[matching_pattern].dup] : []
      end

      def sectional_entry_for_path(path)
        matches = []

        parsed_data.each do |_, section_entries|
          matching_pattern = section_entries.keys.reverse.detect do |pattern|
            path_matches?(pattern, path)
          end

          matches << section_entries[matching_pattern].dup if matching_pattern
        end

        matches
      end

      def data
        if @blob && !@blob.binary?
          @blob.data
        else
          ""
        end
      end

      def get_parsed_data
        if sectional_codeowners?
          get_parsed_sectional_data
        else
          get_parsed_non_sectional_data
        end
      end

      def get_parsed_non_sectional_data
        parsed = {}

        data.lines.each do |line|
          line = line.strip

          next if skip?(line) || line.match?(SECTION_HEADER_REGEX)

          extract_entry_and_populate_parsed_data(line, parsed)
        end

        parsed
      end

      def get_parsed_sectional_data
        parsed_sectional_data = {}
        canonical_section_name = ::Gitlab::CodeOwners::Entry::DEFAULT_SECTION

        parsed_sectional_data[canonical_section_name] = {}

        data.lines.each do |line|
          line = line.strip

          next if skip?(line)

          # Detect section headers, and if found, make sure data structure is
          #   set up to hold the entries it contains, and proceed to the next
          #   line in the file.
          #
          if line.match?(SECTION_HEADER_REGEX)
            parsed_section_name = line[1...-1].strip
            canonical_section_name = find_section_name(parsed_section_name, parsed_sectional_data)

            parsed_sectional_data[canonical_section_name] ||= {}

            next
          end

          extract_entry_and_populate_parsed_data(line, parsed_sectional_data, canonical_section_name)
        end

        parsed_sectional_data
      end

      def find_section_name(section, parsed_sectional_data)
        section_headers = parsed_sectional_data.keys

        return section if section_headers.last == ::Gitlab::CodeOwners::Entry::DEFAULT_SECTION

        section_headers.find { |k| k.casecmp?(section) } || section
      end

      def extract_entry_and_populate_parsed_data(line, parsed, section = nil)
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

      def sectional_codeowners?
        strong_memoize(:sectional_codeowners_check) do
          Feature.enabled?(:sectional_codeowners, @project, default_enabled: false)
        end
      end
    end
  end
end
