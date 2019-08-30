# frozen_string_literal: true

module Packages
  class ConanPackageService
    def initialize(recipe, user, project, package_id = nil)
      @recipe = recipe
      @user = user
      @project = project
      @package_id = package_id
    end

    def recipe_urls
      urls = {}
      return urls unless package

      package.package_files.each do |package_file|
        conan_metadata = package_file.conan_file_metadatum
        next unless recipe_path?(conan_metadata.path)

        urls[package_file.file_name] = "#{base_file_url}/#{recipe_to_url(@recipe)}/-/#{conan_metadata.path}/#{package_file.file_name}"
      end
      urls
    end

    def recipe_snapshot
      digests = {}
      return digests unless package

      package.package_files.each do |package_file|
        conan_metadata = package_file.conan_file_metadatum
        next unless recipe_path?(conan_metadata.path)

        digests[package_file.file_name] = package_file.file_md5
      end
      digests
    end

    def package_urls
      urls = {}
      return urls unless package

      package.package_files.reverse.each do |package_file|
        conan_metadata = package_file.conan_file_metadatum
        next unless package_path?(conan_metadata.path)

        urls[package_file.file_name] = "#{base_file_url}/#{recipe_to_url(@recipe)}/-/#{conan_metadata.path}/#{package_file.file_name}"
      end
      urls
    end

    def package_snapshot
      digests = []
      return digests unless package

      package.package_files.each do |package_file|
        conan_metadata = package_file.conan_file_metadatum
        next unless package_path?(conan_metadata.path)

        digests[package_file.file_name] = package_file.file_md5
      end
      digests
    end

    private

    def base_file_url
      "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files"
    end

    def package
      @package ||= ::Packages::ConanPackageFinder
        .new(@recipe, @user, project: @project).execute
    end

    def package_path?(path)
      path.include?('/package')
    end

    def recipe_path?(path)
      path.include?('/export')
    end

    def recipe_to_url(recipe)
      recipe.tr('@', '/')
    end
  end
end
