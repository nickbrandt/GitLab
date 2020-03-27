# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class GoSumLinker < GoModLinker
      self.file_type = :go_sum

      private

      BASE64 = /(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?/.freeze
      REGEX = Regexp.new("^(?<name>#{NAME.source})\\s+(?<version>#{SEMVER.source})(\/go.mod)?\\s+h1:(?<checksum>#{BASE64.source})$", NAME.options).freeze

      # rubocop: disable CodeReuse/ActiveRecord
      def link_dependencies
        highlighted_lines.map!.with_index do |rich_line, i|
          plain_line = plain_lines[i].chomp
          match = REGEX.match(plain_line)
          next rich_line unless match

          i0, j0 = match.offset(:name)
          i2, j2 = match.offset(:checksum)

          marker = StringRangeMarker.new(plain_line, rich_line.html_safe)
          marker.mark([i0..(j0 - 1), i2..(j2 - 1)]) do |text, left:, right:|
            if left
              url = package_url(text, match[:version])
              url ? link_tag(text, url) : text

            elsif right
              link_tag(text, "https://sum.golang.org/lookup/#{match[:name]}@#{match[:version]}")
            end
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
