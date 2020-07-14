# frozen_string_literal: true

module Gitlab
  module Analytics
    module Reports
      class Series
        attr_reader :id, :title, :data_retrieval_options

        def initialize(id:, title:, data_retrieval_options:)
          @id = id
          @title = title
          @data_retrieval_options = data_retrieval_options
        end
      end
    end
  end
end
