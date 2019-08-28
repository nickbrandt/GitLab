# frozen_string_literal: true

module Packages
  class ConanPackageService
    def initialize(recipe, user, package_id = nil)
      @recipe = recipe
      @user = user
      @package_id = package_id
    end

    def urls(level)
      urls = {}

      package.package_files.each do |package_file|
        conan_metadata = package_file.conan_file_metadatum

        case level
        when :recipe
          next unless recipe_path?(conan_metadata.path)
        when :package
          next unless package_path?(conan_metadata.path)
        else
          next
        end

        urls[package_file.file_name] = "#{base_file_url}/#{@recipe}-/#{conan_metadata.path}/#{package_file.file_name}}"
      end
      urls
    end

    def snapshot(level)
      package.package_files.each do |package_file|
        conan_metadata = package_file.conan_file_metadatum

        case level
        when :recipe
          next unless recipe_path?(conan_metadata.path)
        when :package
          next unless package_path?(conan_metadata.path)
        else
          next
        end

        digests[package_file.file_name] = Digest::MD5.hexdigest(package_file.file)
      end
      digests
    end

    private

    def base_file_url
      "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files"
    end

    def package
      @package ||= ::Packages::ConanPackageFinder
        .new(@recipe, user, project: project).execute
    end

    def package_path?(path)
      path.include?('/package/')
    end

    def recipe_path?(path)
      path.include?('/export/')
    end
  end
end
