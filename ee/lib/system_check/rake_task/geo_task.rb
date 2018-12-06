# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:geo:check rake task
    module GeoTask
      extend RakeTaskHelpers

      def self.name
        'Geo'
      end

      def self.checks
        [
          SystemCheck::Geo::LicenseCheck,
          SystemCheck::Geo::EnabledCheck,
          SystemCheck::Geo::GeoDatabaseConfiguredCheck,
          SystemCheck::Geo::DatabaseReplicationCheck,
          SystemCheck::Geo::FdwEnabledCheck,
          SystemCheck::Geo::FdwSchemaUpToDateCheck,
          SystemCheck::Geo::HttpConnectionCheck,
          SystemCheck::Geo::HTTPCloneEnabledCheck,
          SystemCheck::Geo::ClocksSynchronizationCheck,
          SystemCheck::App::GitUserDefaultSSHConfigCheck,
          SystemCheck::Geo::AuthorizedKeysCheck,
          SystemCheck::Geo::AuthorizedKeysFlagCheck,
          SystemCheck::App::HashedStorageEnabledCheck,
          SystemCheck::App::HashedStorageAllProjectsCheck
        ]
      end
    end
  end
end
