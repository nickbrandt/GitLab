# frozen_string_literal: true

module SystemCheck
  module Geo
    class FdwSchemaUpToDateCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo tracking database Foreign Data Wrapper schema is up-to-date?'

      NOT_SECONDARY_NODE = 'not a secondary node'.freeze
      FDW_NOT_CONFIGURED = 'foreign data wrapper is not configured'.freeze

      def skip?
        unless Gitlab::Geo.secondary?
          self.skip_reason = NOT_SECONDARY_NODE

          return true
        end

        unless Gitlab::Geo::Fdw.enabled?
          self.skip_reason = FDW_NOT_CONFIGURED

          return true
        end

        false
      end

      def check?
        Gitlab::Geo::Fdw.foreign_tables_up_to_date?
      end

      def show_error
        try_fixing_it(
          'Run the following command to refresh the FDW schema:',
          'gitlab-rake geo:db:refresh_foreign_tables'
        )

        for_more_information('doc/administration/geo/replication/troubleshooting.md#geo-database-has-an-outdated-fdw-remote-schema-error')
      end
    end
  end
end
