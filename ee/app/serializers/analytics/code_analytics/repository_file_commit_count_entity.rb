# frozen_string_literal: true

module Analytics
  module CodeAnalytics
    class RepositoryFileCommitCountEntity < Grape::Entity
      expose(:id) { |model| model.repository_file.id }
      expose(:name) { |model| model.repository_file.file_path }
      expose :count
    end
  end
end
