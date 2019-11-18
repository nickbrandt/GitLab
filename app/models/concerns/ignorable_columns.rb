# frozen_string_literal: true

module IgnorableColumns
  extend ActiveSupport::Concern

  class_methods do
    # Ignore database columns in a model
    #
    # Indicate the earliest date and release we can stop ignoring the column with +remove_after+ (a date string) and +remove_with+ (a release)
    def ignore_columns(*columns, remove_after:, remove_with:)
      raise ArgumentError, 'Please indicate when we can stop ignoring columns with remove_after, example: ignore_columns(:name, remove_after: \'2019-12-01\', remove_with: \'12.6\')' unless remove_after && remove_with

      self.ignored_columns += columns.flatten

      @ignored_columns_details ||= {}

      columns.flatten.each do |column|
        @ignored_columns_details[column] = { remove_after: remove_after, remove_with: remove_with }
      end
    end

    alias_method :ignore_column, :ignore_columns

    def ignored_columns_details
      @ignored_columns_details || {}
    end
  end
end
