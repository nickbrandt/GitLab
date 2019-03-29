# frozen_string_literal: true

module EE
  module Gitlab
    module FakeApplicationSettings
      def elasticsearch_indexes_project?(_project)
        false
      end

      def elasticsearch_indexes_namespace?(_namespace)
        false
      end
    end
  end
end
