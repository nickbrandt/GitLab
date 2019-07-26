namespace :gitlab do
  namespace :ldap do
    desc 'GitLab | LDAP | Run a GroupSync'
    task group_sync: :gitlab_environment do
      if Gitlab::Auth::LDAP::Config.group_sync_enabled?
        $stdout.puts 'LDAP GroupSync is enabled.'
        $stdout.puts 'Starting GroupSync...'

        begin
          EE::Gitlab::Auth::LDAP::Sync::Groups.execute
          $stdout.puts 'Finished GroupSync.'
        rescue => exception
          warn "The GroupSync failed with the following error: #{exception}"
        end

      else
        $stdout.puts 'LDAP GroupSync is not enabled.'
      end
    end
  end
end
