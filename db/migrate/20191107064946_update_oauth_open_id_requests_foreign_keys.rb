# frozen_string_literal: true

# rubocop: disable Migration/AddConcurrentForeignKey

class UpdateOauthOpenIdRequestsForeignKeys < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_foreign_key_if_exists(:oauth_openid_requests, column: :access_grant_id)
    add_foreign_key(:oauth_openid_requests, :oauth_access_grants, column: :access_grant_id, on_delete: :cascade)
  end

  def down
    remove_foreign_key_if_exists(:oauth_openid_requests, column: :access_grant_id)
    add_foreign_key(:oauth_openid_requests, :oauth_access_grants, column: :access_grant_id, on_delete: false, name: 'fk_oauth_openid_requests_oauth_access_grants_access_grant_id')
  end
end
