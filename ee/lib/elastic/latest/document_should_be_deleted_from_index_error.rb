# frozen_string_literal: true

module Elastic
  module Latest
    class DocumentShouldBeDeletedFromIndexError < StandardError
      attr_reader :record_id, :class_name

      def initialize(record_id, class_name)
        @id, @class_name = record_id, class_name
      end

      def message
        "#{class_name} with id #{@database_record.es_id} should be deleted from the index."
      end
    end
  end
end
