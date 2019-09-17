# frozen_string_literal: true

module EE
  module Gitlab
    module UrlBuilder
      extend ::Gitlab::Utils::Override

      override :url
      def url
        return project_design_url(object.project, object) if object.is_a?(DesignManagement::Design)

        super
      end
    end
  end
end
