# frozen_string_literal: true

module API
  module ProjectsRelationBuilder
    extend ActiveSupport::Concern

    class_methods do
      # Prepare the given projects relation, e.g. perform preloading.
      def prepare_relation(projects_relation, options = {})
        preload_relation(projects_relation, options)
      end

      def preload_relation(projects_relation, options = {})
        projects_relation
      end
    end
  end
end
