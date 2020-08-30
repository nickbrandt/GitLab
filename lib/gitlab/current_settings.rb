# frozen_string_literal: true

module Gitlab
  module CurrentSettings
    class << self
      def current_application_settings
        Gitlab::SafeRequestStore.fetch(:current_application_settings) { ensure_application_settings! }
      end

      def expire_current_application_settings
        ::ApplicationSetting.expire
        Gitlab::SafeRequestStore.delete(:current_application_settings)
      end

      def clear_in_memory_application_settings!
        @in_memory_application_settings = nil
      end

      def method_missing(name, *args, &block)
        current_application_settings.send(name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
      end

      def respond_to_missing?(name, include_private = false)
        current_application_settings.respond_to?(name, include_private) || super
      end

      private

      def ensure_application_settings!
        cached_application_settings || uncached_application_settings
      end

      def cached_application_settings
        return in_memory_application_settings if ENV['IN_MEMORY_APPLICATION_SETTINGS'] == 'true'

        begin
          ::ApplicationSetting.cached
        rescue
          # In case Redis isn't running
          # or the Redis UNIX socket file is not available
          # or the DB is not running (we use migrations in the cache key)
        end
      end

      def uncached_application_settings
        return fake_application_settings if Gitlab::Runtime.rake? && !connect_to_db?

        current_settings = ::ApplicationSetting.current
        # If there are pending migrations, it's possible there are columns that
        # need to be added to the application settings. To prevent Rake tasks
        # and other callers from failing, use any loaded settings and return
        # defaults for missing columns.
        if Gitlab::Runtime.rake? && ActiveRecord::Base.connection.migration_context.needs_migration?
          db_attributes = current_settings&.attributes || {}
          fake_application_settings(db_attributes)
        elsif current_settings.present?
          current_settings
        else
          check_application_settings_schema!

          ::ApplicationSetting.create_from_defaults
        end
      end

      def fake_application_settings(attributes = {})
        Gitlab::FakeApplicationSettings.new(::ApplicationSetting.defaults.merge(attributes || {}))
      end

      def in_memory_application_settings
        @in_memory_application_settings ||= ::ApplicationSetting.build_from_defaults
      end

      # Due to the frequency with which settings are accessed, it is
      # likely that during a backup restore a running GitLab process
      # will insert a new `application_settings` row before the
      # constraints have been added to the table. This would add an
      # extra row with ID 1 and prevent the primary key constraint from
      # being added, which made ActiveRecord throw a
      # IrreversibleOrderError anytime the settings were accessed
      # (https://gitlab.com/gitlab-org/gitlab/-/issues/36405).  To
      # prevent this from happening, we do a sanity check that the
      # primary key constraint is present before inserting a new entry.
      def check_application_settings_schema!
        return if ActiveRecord::Base.connection.primary_key(ApplicationSetting.table_name).present?

        raise "The `application_settings` table is missing a primary key constraint in the database schema"
      end

      def connect_to_db?
        # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
        active_db_connection = ActiveRecord::Base.connection.active? rescue false

        active_db_connection &&
          Gitlab::Database.cached_table_exists?('application_settings')
      rescue ActiveRecord::NoDatabaseError
        false
      end
    end
  end
end
