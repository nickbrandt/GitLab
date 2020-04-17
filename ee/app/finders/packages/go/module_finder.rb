# frozen_string_literal: true

module Packages
  module Go
    class ModuleFinder
      include ::API::Helpers::Packages::Go::ModuleHelpers

      GITLAB_GO_URL = (Settings.build_gitlab_go_url + '/').freeze

      attr_reader :project, :module_name

      def initialize(project, module_name)
        module_name = CGI.unescape(module_name)
        module_name = Pathname.new(module_name).cleanpath.to_s

        @project = project
        @module_name = module_name
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        return if @module_name.blank? || !@module_name.start_with?(GITLAB_GO_URL)

        module_path = @module_name[GITLAB_GO_URL.length..].split('/')
        project_path = project.full_path.split('/')
        return unless module_path.take(project_path.length) == project_path

        Packages::GoModule.new(@project, @module_name, module_path.drop(project_path.length).join('/'))
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
