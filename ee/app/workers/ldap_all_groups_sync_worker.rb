# frozen_string_literal: true

class LdapAllGroupsSyncWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :authentication_and_authorization
  worker_has_external_dependencies!

  def perform
    return unless Gitlab::Auth::LDAP::Config.group_sync_enabled?

    logger.info 'Started LDAP group sync'
    EE::Gitlab::Auth::LDAP::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
