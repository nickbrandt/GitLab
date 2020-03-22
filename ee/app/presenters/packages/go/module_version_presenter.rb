# frozen_string_literal: true

module Packages
  module Go
    class ModuleVersionPresenter
      def initialize(version)
        @version = version
      end

      def name
        @version.name
      end

      def time
        @version.tag.dereferenced_target.committed_date
      end
    end
  end
end