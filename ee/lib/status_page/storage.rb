# frozen_string_literal: true

module StatusPage
  module Storage
    # Limit the amount of the recent incidents in the JSON list
    MAX_RECENT_INCIDENTS = 20
    # Limit the amount of comments per incident
    MAX_COMMENTS = 100

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
