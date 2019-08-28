# frozen_string_literal: true

module Packages
  class ConanService
    def initialize(recipe, package_id = nil)
      @recipe = recipe
      @package_id = package_id
    end

    def urls
      urls = {}
      package.package_files.each do |file|
        urls[filename] = "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{@recipe}-/#{params[:path]}/#{params[:filename]}"
      end
      urls
    end

    def snapshot
      digests = {}
      package.package_files.each do |package_file|
        digests[package_file.file_name] = Digest::MD5.hexdigest(package_file.file)
      end
      digests
    end

    private

    def package
      @package ||= ::Packages::ConanPackageFinder
        .new(@recipe, current_user, project: project).execute
    end
  end
end
