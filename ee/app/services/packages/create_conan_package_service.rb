# frozen_string_literal: true
module Packages
  class CreateConanPackageService < BaseService
    def execute
      Rails.logger.info "Create"
      project.packages.create!(
        name: params[:name],
        version: params[:version],
        package_type: :conan
      )
    end
  end
end
