# frozen_string_literal: true

module EE
  module PackagesHelper
    def package_sort_path(options = {})
      "#{request.path}?#{options.to_param}"
    end

    def vue_package_list_enabled_for?(subject)
      ::Feature.enabled?(:vue_package_list, subject)
    end
  end
end
