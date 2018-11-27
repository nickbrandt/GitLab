# frozen_string_literal: true

namespace :gitlab do
  namespace :geo do
    desc 'GitLab | Check Geo configuration and dependencies'
    task check: :gitlab_environment do
      warn_user_is_not_gitlab

      checks = [
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
        SystemCheck::Geo::AuthorizedKeysFlagCheck
      ]

      SystemCheck.run('Geo', checks)
    end
  end
end
