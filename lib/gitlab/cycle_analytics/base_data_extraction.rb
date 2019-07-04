# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module BaseDataExtraction
      private

      def projects
        group ? extract_projects(@options) : [@project] # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def group
        @group ||= @options.fetch(:group, nil) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def extract_projects(options)
        projects = Project.inside_path(group.full_path)
        projects = projects.where(name: options[:projects]) if options[:projects]
        projects
      end
    end
  end
end
