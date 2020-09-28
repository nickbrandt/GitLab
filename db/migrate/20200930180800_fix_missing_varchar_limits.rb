# frozen_string_literal: true

class FixMissingVarcharLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  COLUMNS_TO_CHANGE = {
    appearances: %w[header_logo logo title],
    application_settings: %w[after_sign_out_path home_page_url],
    approvers: %w[target_type],
    backup_labels: %w[color title],
    broadcast_messages: %w[color font],
    ci_runners: %w[architecture description name platform revision token version],
    ci_triggers: %w[token],
    ci_variables: %w[encrypted_value_iv encrypted_value_salt],
    emails: %w[email],
    identities: %w[extern_uid provider],
    keys: %w[fingerprint title type],
    label_links: %w[target_type],
    labels: %w[color title],
    ldap_group_links: %w[cn provider],
    lfs_objects: %w[file oid],
    members: %w[invite_email invite_token source_type type],
    milestones: %w[state title],
    oauth_access_tokens: %w[refresh_token scopes token],
    protected_branches: %w[name],
    push_rules: %w[author_email_regex commit_message_regex delete_branch_regex file_name_regex force_push_regex],
    releases: %w[tag],
    schema_migrations: %w[version],
    snippets: %w[file_name title type],
    subscriptions: %w[subscribable_type],
    tags: %w[name]
  }.freeze

  disable_ddl_transaction!

  def up
    COLUMNS_TO_CHANGE.each do |table, columns|
      transaction do
        columns.each do |column|
          change_column table, column, :text
        end
      end
    end

    transaction do
      change_table :oauth_access_grants do |t|
        t.change :scopes, :text, default: ''
        t.change :token, :text
      end
    end

    transaction do
      change_table :oauth_applications do |t|
        t.change :name, :text
        t.change :owner_type, :text
        t.change :scopes, :text, default: ''
        t.change :secret, :text
        t.change :uid, :text
      end
    end

    change_column :web_hooks, :type, :text, default: 'ProjectHook'
  end

  def down
    # no op
  end
end
