# frozen_string_literal: true

module EE
  module PackagesHelper
    def package_sort_path(options = {})
      "#{request.path}?#{options.to_param}"
    end

    def vue_package_list_enabled_for?(subject)
      ::Feature.enabled?(:vue_package_list, subject)
    end

    def nuget_package_registry_url(project_id)
      expose_url(api_v4_projects_packages_nuget_index_path(id: project_id, format: '.json'))
    end

    def package_registry_instance_url(registry_type)
      expose_url("api/#{::API::API.version}/packages/#{registry_type}")
    end

    def package_registry_project_url(project_id, registry_type = :maven)
      project_api_path = expose_path(api_v4_projects_path(id: project_id))
      package_registry_project_path = "#{project_api_path}/packages/#{registry_type}"
      expose_url(package_registry_project_path)
    end
  end
end
