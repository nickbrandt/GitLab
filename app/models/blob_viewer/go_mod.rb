# frozen_string_literal: true

module BlobViewer
  class GoMod < DependencyManager
    include ServerSide

    self.file_types = %i(go_mod go_sum)

    def manager_name
      'Go Modules'
    end

    def manager_url
      'https://golang.org/ref/mod'
    end

    def package_type
      'go'
    end

    def package_name
      return if blob.name != 'go.mod'
      return @package_name unless @package_name.nil?
      return unless blob.data.starts_with? 'module '

      @package_name ||= blob.data.partition("\n").first[7..]
    end

    def package_url
      return unless Gitlab::UrlSanitizer.valid?("https://#{package_name}")

      if package_name.starts_with? Settings.build_gitlab_go_url + '/'
        "#{Gitlab.config.gitlab.protocol}://#{package_name}"
      else
        "https://pkg.go.dev/#{package_name}"
      end
    end
  end
end
