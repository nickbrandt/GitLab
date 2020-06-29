# frozen_string_literal: true

raise "PostgreSQL is the only supported database from GitLab 12.1" unless
  Gitlab::Database.postgresql?

begin
  puts ERB.new(Rainbow.new.wrap(<<~EOS).red).result unless Gitlab::Database.postgresql_minimum_supported_version? # rubocop:disable Rails/Output

              ██     ██  █████  ██████  ███    ██ ██ ███    ██  ██████ 
              ██     ██ ██   ██ ██   ██ ████   ██ ██ ████   ██ ██      
              ██  █  ██ ███████ ██████  ██ ██  ██ ██ ██ ██  ██ ██   ███ 
              ██ ███ ██ ██   ██ ██   ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
               ███ ███  ██   ██ ██   ██ ██   ████ ██ ██   ████  ██████  

    ******************************************************************************
      You are using PostgreSQL <%= Gitlab::Database.version %>, but PostgreSQL >= <%= Gitlab::Database::MINIMUM_POSTGRES_VERSION %>
      is required for this version of GitLab.
      <% if Rails.env.development? || Rails.env.test? %>
      If using gitlab-development-kit, please find the relevant steps here:
        https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/master/doc/howto/postgresql.md#upgrade-postgresql
      <% end %>
      Please upgrade your environment to a supported PostgreSQL version, see
      https://docs.gitlab.com/ee/install/requirements.html#database for details.
    ******************************************************************************
  EOS
rescue ActiveRecord::ActiveRecordError, PG::Error
  # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
end
