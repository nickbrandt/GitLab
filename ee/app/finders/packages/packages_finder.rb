# frozen_string_literal: true

module Packages
  class PackagesFinder
    attr_reader :params, :project

    def initialize(project, params = {})
      @project = project
      @params = params

      params[:order_by] ||= 'created_at'
      params[:sort] ||= 'asc'
    end

    def execute
      packages = project.packages
      packages = filter_by_package_type(packages)
      packages = order_packages(packages)
      packages
    end

    private

    def filter_by_package_type(packages)
      return packages unless params[:package_type]

      packages.with_package_type(params[:package_type])
    end

    def order_packages(packages)
      packages.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
    end
  end
end
