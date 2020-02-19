# frozen_string_literal: true

module DependencyProxy
  module Packages
    class ProxyService < ::BaseService
      class DownloadError < StandardError
        attr_reader :http_status

        def initialize(message, http_status)
          @http_status = http_status

          super(message)
        end
      end

      def initialize(url)
        @url = url
        @temp_file = Tempfile.new
      end

      def execute
        response = nil
        File.open(@temp_file.path, "wb") do |file|
          response = Gitlab::HTTP.get(@url, stream_body: true) do |fragment|
            if [301, 302, 307].include?(fragment.code)
              # do nothing
            elsif fragment.code == 200
              file.write(fragment)
            else
              raise DownloadError.new('Non-success response code on downloading response', fragment.code)
            end
          end
        end

        success(file: @temp_file, response: response)
      rescue Timeout::Error => exception
        error(exception.message, 599)
      rescue DownloadError => exception
        error(exception.message, exception.http_status)
      end
    end
  end
end
