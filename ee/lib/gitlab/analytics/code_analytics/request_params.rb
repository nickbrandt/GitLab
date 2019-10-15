# frozen_string_literal: true

module Gitlab
  module Analytics
    module CodeAnalytics
      class RequestParams
        include ActiveModel::Model
        include ActiveModel::Validations

        attr_writer :file_count

        validates :file_count, presence: true, numericality: {
          only_integer: true,
          greater_than: 0,
          less_than_or_equal_to: ::Analytics::CodeAnalytics::RepositoryFileCommit::MAX_FILE_COUNT
        }

        # The date range will be customizable later, for now we load data for the last 30 days
        def from
          30.days.ago
        end

        def to
          Date.today
        end

        def file_count
          Integer(@file_count) if @file_count
        end
      end
    end
  end
end
