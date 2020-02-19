# frozen_string_literal: true

class AddUserDetailsSyncTriggersToUsers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute <<-EOF.strip_heredoc
    CREATE OR REPLACE FUNCTION sync_user_details() RETURNS TRIGGER AS
    $BODY$
    BEGIN
      INSERT INTO
          user_details (
            user_id,
            bio,
            location,
            organization,
            linkedin,
            twitter,
            skype,
            website_url
          )
          VALUES (
            new.id,
            substring(COALESCE(new.bio, '') from 1 for 255),
            substring(COALESCE(new.location, '') from 1 for 255),
            substring(COALESCE(new.organization, '') from 1 for 255),
            substring(COALESCE(new.linkedin, '') from 1 for 2048),
            substring(COALESCE(new.twitter, '') from 1 for 2048),
            substring(COALESCE(new.skype, '') from 1 for 2048),
            substring(COALESCE(new.website_url, '') from 1 for 2048)
          )
      ON CONFLICT (user_id)
        DO UPDATE SET
          "bio" = EXCLUDED."bio",
          "location" = EXCLUDED."location",
          "organization" = EXCLUDED."organization",
          "linkedin" = EXCLUDED."linkedin",
          "twitter" = EXCLUDED."twitter",
          "skype" = EXCLUDED."skype",
          "website_url" = EXCLUDED."website_url";

      RETURN new;
    END;
    $BODY$
    language plpgsql;
    EOF

    execute <<-EOF.strip_heredoc
    CREATE TRIGGER trigger_user_details_sync_on_update
      AFTER UPDATE ON users
      FOR EACH ROW
      WHEN (
        (OLD.bio IS DISTINCT FROM NEW.bio) OR
        (OLD.location IS DISTINCT FROM NEW.location) OR
        (OLD.organization IS DISTINCT FROM NEW.organization) OR
        (OLD.linkedin IS DISTINCT FROM NEW.linkedin) OR
        (OLD.twitter IS DISTINCT FROM NEW.twitter) OR
        (OLD.skype IS DISTINCT FROM NEW.skype) OR
        (OLD.website_url IS DISTINCT FROM NEW.website_url)
      )
      EXECUTE PROCEDURE sync_user_details();
    EOF

    execute <<-EOF.strip_heredoc
    CREATE TRIGGER trigger_user_details_sync_on_insert
      AFTER INSERT ON users
      FOR EACH ROW
      WHEN (
        (COALESCE(NEW.bio, '') IS DISTINCT FROM '') OR
        (COALESCE(NEW.location, '') IS DISTINCT FROM '') OR
        (COALESCE(NEW.organization, '') IS DISTINCT FROM '') OR
        (COALESCE(NEW.linkedin, '') IS DISTINCT FROM '') OR
        (COALESCE(NEW.twitter, '') IS DISTINCT FROM '') OR
        (COALESCE(NEW.skype, '') IS DISTINCT FROM '') OR
        (COALESCE(NEW.website_url, '') IS DISTINCT FROM '')
      )
      EXECUTE PROCEDURE sync_user_details();
    EOF
  end

  def down
    execute 'DROP TRIGGER IF EXISTS trigger_user_details_sync_on_insert ON users'
    execute 'DROP TRIGGER IF EXISTS trigger_user_details_sync_on_update ON users'
    execute 'DROP FUNCTION IF EXISTS sync_user_details();'
  end
end
