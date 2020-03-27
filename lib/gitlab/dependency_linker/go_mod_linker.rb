# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class GoModLinker < BaseLinker
      self.file_type = :go_mod

      private

      SEMVER = /
        v (?# prefix)
        (0|[1-9]\d*) (?# major)
        \.(0|[1-9]\d*) (?# minor)
        \.(0|[1-9]\d*) (?# patch)
        (?:-((?:\d*[a-zA-Z\-][0-9a-zA-Z\-]*|0|[1-9]\d*)(?:\.(?:\d*[a-zA-Z-][0-9a-zA-Z-]*|0|[1-9]\d*))*))? (?# prerelease)
        (?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))? (?# build)
      /ix.freeze
      NAME = Gitlab::Regex.go_package_regex
      REGEX = Regexp.new("(?<name>#{NAME.source})(?:\\s+(?<version>#{SEMVER.source}))?", NAME.options).freeze

      def package_url(name, version = nil)
        return unless Gitlab::UrlSanitizer.valid?("https://#{name}")

        if name.starts_with?(Settings.build_gitlab_go_url + '/')
          "#{Gitlab.config.gitlab.protocol}://#{name}"
        else
          url = pkg_go_dev_url(name)
          url += "@#{version}" if version
          url
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def link_dependencies
        highlighted_lines.map!.with_index do |rich_line, i|
          plain_line = plain_lines[i].chomp
          match = REGEX.match(plain_line)
          next rich_line unless match

          i, j = match.offset(:name)
          marker = StringRangeMarker.new(plain_line, rich_line.html_safe)
          marker.mark([i..(j - 1)]) do |text, left:, right:|
            url = package_url(text, match[:version])
            url ? link_tag(text, url) : text
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
