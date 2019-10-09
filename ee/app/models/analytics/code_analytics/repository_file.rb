# frozen_string_literal: true

module Analytics
  module CodeAnalytics
    class RepositoryFile < ApplicationRecord
      self.table_name = 'analytics_repository_files'

      belongs_to :project
    end
  end
end
