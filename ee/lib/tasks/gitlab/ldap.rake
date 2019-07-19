namespace :gitlab do
  namespace :ldap do
    desc 'GitLab | LDAP | Run a GroupSync'
    task :group_sync => :gitlab_environment do |_, args|
      def execute
        return unless group_sync_enabled?
        group_sync
      end

      def group_sync
        $stdout.puts 'Starting GroupSync...'
        EE::Gitlab::Auth::LDAP::Sync::Groups.execute
        $stdout.puts 'Finished GroupSync.'
      rescue => e
        $stderr.puts e
      end

      def group_sync_enabled?
        if Gitlab::Auth::LDAP::Config.group_sync_enabled?
          $stdout.puts 'LDAP GroupSync is enabled.'
        else
          $stdout.puts 'LDAP GroupSync is not enabled.'
        end
      end

      execute
    end
  end
end
