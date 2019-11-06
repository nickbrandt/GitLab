# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class UpdateExistingPublicProjectsInPrivateGroupsToPrivateProjects
      BATCH_SIZE = 100

      class Namespace < ActiveRecord::Base
        self.table_name = 'namespaces'
      end

      class Project < ActiveRecord::Base
        include EachBatch

        belongs_to :namespace

        scope :with_group_visibility, ->(visibility) do
          joins(:namespace)
            .where(namespaces: { type: 'Group', visibility_level: visibility })
            .where('projects.visibility_level > ?', visibility)
        end

        self.table_name = 'projects'
      end

      def perform(visibility)
        Project.with_group_visibility(visibility).each_batch(of: BATCH_SIZE) do |batch|
          batch.update_all(visibility_level: visibility)
        end
      end
    end
  end
end
