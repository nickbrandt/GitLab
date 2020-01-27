# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Project model for this migration
    class Project < ActiveRecord::Base
      include EachBatch
    end

    ENABLED = 20
    INSERT_BATCH_SIZE = 10_000

    # This migration creates missing project_features records
    # for the projects within the given range of ids
    class FixProjectsWithoutProjectFeature
      def perform(from_id, to_id)
        Project.transaction do
          projects = Project.where(<<~SQL, from_id, to_id)
            projects.id BETWEEN ? AND ?
            AND NOT EXISTS (
              SELECT 1 FROM project_features
              WHERE project_features.project_id = projects.id
            )
          SQL

          projects.each_batch(of: INSERT_BATCH_SIZE) do |batch|
            insert_missing_records(batch)
          end
        end
      end

      private

      def insert_missing_records(projects)
        features = projects.map do |project|
          record = {
            project_id: project.id,
            merge_requests_access_level: ENABLED,
            issues_access_level: ENABLED,
            wiki_access_level: ENABLED,
            snippets_access_level: ENABLED,
            builds_access_level: ENABLED,
            repository_access_level: ENABLED,
            pages_access_level: ENABLED,
            forking_access_level: ENABLED
          }

          record['created_at'] = record['updated_at'] = Time.now.to_s(:db)

          record
        end

        Gitlab::Database.bulk_insert(:project_features, features, on_conflict: :do_nothing)

        logger.info(message: "FixProjectsWithoutProjectFeature: created missing project_features for Projects #{projects.map(&:id).join(', ')}")
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
