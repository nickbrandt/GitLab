# frozen_string_literal: true

module EE
  module PackagesHelper
    def package_sort_path(options = {})
      "#{request.path}?#{options.to_param}"
    end

    def vue_package_list_enabled_for?(subject)
      ::Feature.enabled?(:vue_package_list, subject)
    end

    def npm_package_registry_url
      ::Gitlab::Utils.append_path(::Gitlab.config.gitlab.url, expose_path(api_v4_packages_npm_package_name_path))
    end

    def package_registry_project_url(project_id, registry_type = :maven)
      project_api_path = expose_path(api_v4_projects_path(id: project_id))
      package_registry_project_path = "#{project_api_path}/packages/#{registry_type}"
      ::Gitlab::Utils.append_path(::Gitlab.config.gitlab.url, package_registry_project_path)
    end
  end
end
