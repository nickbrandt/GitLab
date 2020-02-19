# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateToUserDetails
      USER_QUERY_CONDITION = <<-EOF.strip_heredoc
      (COALESCE(bio, '') IS DISTINCT FROM '') OR
      (COALESCE(location, '') IS DISTINCT FROM '') OR
      (COALESCE(organization, '') IS DISTINCT FROM '') OR
      (COALESCE(linkedin, '') IS DISTINCT FROM '') OR
      (COALESCE(twitter, '') IS DISTINCT FROM '') OR
      (COALESCE(skype, '') IS DISTINCT FROM '') OR
      (COALESCE(website_url, '') IS DISTINCT FROM '')
      EOF

      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      class UserDetails < ActiveRecord::Base
        self.table_name = 'user_details'
      end

      def perform(start_id, stop_id)
        relation = User
          .select("id AS user_id",
                  "substring(COALESCE(bio, '') from 1 for 255) AS bio",
                  "substring(COALESCE(location, '') from 1 for 255) AS location",
                  "substring(COALESCE(organization, '') from 1 for 255) AS orgainzation",
                  "substring(COALESCE(linkedin, '') from 1 for 2048) AS linkedin",
                  "substring(COALESCE(twitter, '') from 1 for 2048) AS twitter",
                  "substring(COALESCE(skype, '') from 1 for 2048) AS skype",
                  "substring(COALESCE(website_url, '') from 1 for 2048) AS website_url"
                 )
                   .where(USER_QUERY_CONDITION)
                   .where(id: (start_id..stop_id))

        ActiveRecord::Base.connection.execute <<-EOF.strip_heredoc
          INSERT INTO user_details
          (user_id, bio, location, organization, linkedin, twitter, skype, website_url)
          #{relation.to_sql}
          ON CONFLICT (user_id)
          DO UPDATE SET
            "bio" = EXCLUDED."bio",
            "location" = EXCLUDED."location",
            "organization" = EXCLUDED."organization",
            "linkedin" = EXCLUDED."linkedin",
            "twitter" = EXCLUDED."twitter",
            "skype" = EXCLUDED."skype",
            "website_url" = EXCLUDED."website_url";
        EOF
      end
    end
  end
end
