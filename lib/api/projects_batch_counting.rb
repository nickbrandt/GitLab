# frozen_string_literal: true

module API
  module ProjectsBatchCounting
    extend ActiveSupport::Concern

    class_methods do
      def forks_counting_projects(projects)
        projects
      end

      def execute_batch_counting(projects)
        ::Projects::BatchForksCountService.new(forks_counting_projects(projects)).refresh_cache

        ::Projects::BatchOpenIssuesCountService.new(projects).refresh_cache
      end
    end
  end
end
