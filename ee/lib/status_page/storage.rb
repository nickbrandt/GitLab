# frozen_string_literal: true

module StatusPage
  module Storage
    def self.details_path(id)
      "incident/#{id}.json"
    end

    def self.list_path
      'list.json'
    end

    class Error < StandardError
      def initialize(bucket:, error:, **args)
        super(
          "Error occured #{error.class.name.inspect} " \
          "for bucket #{bucket.inspect}. " \
          "Arguments: #{args.inspect}"
        )
      end
    end
  end
end
