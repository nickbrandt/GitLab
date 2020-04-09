# frozen_string_literal: true

module Packages
  module Go
    class ModuleFinder
      include ::API::Helpers::Packages::Go::ModuleHelpers

      attr_reader :project, :module_name

      def initialize(project, module_name)
        module_name = Pathname.new(module_name).cleanpath.to_s

        @project = project
        @module_name = module_name
      end

      def execute
        return if @module_name.blank?

        if @module_name == package_base
          Packages::GoModule.new(@project, @module_name, '')
        elsif @module_name.start_with?(package_base + '/')
          Packages::GoModule.new(@project, @module_name, @module_name[(package_base.length + 1)..])
        else
          nil
        end
      end

      private

      def package_base
        @package_base ||= Gitlab::Routing.url_helpers.project_url(@project).split('://', 2)[1]
      end
    end
  end
end
