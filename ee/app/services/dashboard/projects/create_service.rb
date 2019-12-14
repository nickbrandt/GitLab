# frozen_string_literal: true

module Dashboard
  module Projects
    class CreateService
      Result = Struct.new(:added_project_ids, :invalid_project_ids, :duplicate_project_ids)

      def initialize(user, projects_relation, feature:)
        @user = user
        @projects_relation = projects_relation
        @feature = feature
      end

      def execute(project_ids)
        projects_to_add = load_projects(project_ids)

        invalid = find_invalid_ids(projects_to_add, project_ids)
        added, duplicate = add_projects(projects_to_add)

        Result.new(added.map(&:id), invalid, duplicate.map(&:id))
      end

      private

      attr_reader :feature,
                  :projects_relation,
                  :user

      def load_projects(project_ids)
        Dashboard::Projects::ListService.new(user, feature: feature).execute(project_ids)
      end

      def find_invalid_ids(projects_to_add, project_ids)
        found_ids = projects_to_add.map(&:id).map(&:to_s)

        project_ids.map(&:to_s) - found_ids
      end

      def add_projects(projects)
        projects.partition(&method(:add_project))
      end

      def add_project(project)
        projects_relation << project
        true
      rescue ActiveRecord::RecordInvalid
        false
      end
    end
  end
end
