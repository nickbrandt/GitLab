# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class Issue < ActiveRecord::Base
          include IsolatedMentionable
          include CacheMarkdownField

          attr_mentionable :title, pipeline: :single_line
          attr_mentionable :description
          cache_markdown_field :title, pipeline: :single_line
          cache_markdown_field :description, issuable_state_filter_enabled: true

          self.table_name = 'issues'

          belongs_to :author, class_name: "User"
          belongs_to :project
        end
      end
    end
  end
end
