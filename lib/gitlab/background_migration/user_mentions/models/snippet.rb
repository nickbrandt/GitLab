# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        class Snippet < ActiveRecord::Base
          include IsolatedMentionable

          attr_mentionable :title, pipeline: :single_line
          attr_mentionable :description

          self.table_name = 'snippets'

          belongs_to :author, class_name: "User"
          belongs_to :project
        end
      end
    end
  end
end
