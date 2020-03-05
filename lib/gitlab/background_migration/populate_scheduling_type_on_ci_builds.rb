# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateSchedulingTypeOnCiBuilds
      class Build < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled

        include ::EachBatch

        def self.builds_to_update
          where(type: %w[Ci::Build Ci::Bridge], scheduling_type: nil)
        end
      end

      class BuildNeed < ActiveRecord::Base
        self.table_name = 'ci_build_needs'
      end

      def perform(start_id, stop_id)
        needs = BuildNeed.where('ci_builds.id = ci_build_needs.build_id').select(1)
        update_query = "scheduling_type = CASE WHEN (EXISTS (#{needs.to_sql})) THEN 1 ELSE 0 END"

        Build.builds_to_update
             .where(id: start_id..stop_id)
             .update_all(update_query)
      end
    end
  end
end
