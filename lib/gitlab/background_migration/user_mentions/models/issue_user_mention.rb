# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class IssueUserMention < ActiveRecord::Base
          self.table_name = 'issue_user_mentions'

          def self.resource_foreign_key
            "issue_id"
          end
        end
      end
    end
  end
end
