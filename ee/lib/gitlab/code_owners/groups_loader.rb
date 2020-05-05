# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class GroupsLoader
      def initialize(project, extractor)
        @project = project
        @extractor = extractor
      end

      def load_to(entries)
        groups = load_groups
        entries.each do |entry|
          entry.add_matching_groups_from(groups)
        end
      end

      private

      attr_reader :extractor, :project

      def load_groups
        return Group.none if extractor.names.empty?

        groups = project.invited_groups.where_full_path_in(extractor.names)
        group_list = groups.with_route.with_users.to_a

        if extractor.names.include?(project.group&.full_path)
          project.group.users.load

          group_list << project.group
        end

        group_list
      end
    end
  end
end
