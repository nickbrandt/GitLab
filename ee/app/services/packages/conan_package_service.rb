# frozen_string_literal: true

module Packages
  class ConanPackageService < BaseService
    def initialize(recipe)
      @name, @version, @user, @channel = recipe.split('@').map { |e| e.split('/') }.flatten
    end

    def get_conanfile_download_urls()

    end

    private

    def get_download_conanfile_urls()
      []
    end
  end
end
