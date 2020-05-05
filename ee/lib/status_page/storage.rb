# frozen_string_literal: true

module StatusPage
  module Storage
    # Size limit of the generated JSON uploaded to CDN.
    JSON_MAX_SIZE = 1.megabyte
    # Limit the amount of the recent incidents in the JSON list
    MAX_RECENT_INCIDENTS = 20
    # Limit the amount of comments per incident
    MAX_COMMENTS = 100
    # Limit on paginated responses
    MAX_KEYS_PER_PAGE = 1_000
    MAX_PAGES = 5
    MAX_IMAGE_UPLOADS = MAX_KEYS_PER_PAGE * MAX_PAGES

    def self.details_path(id)
      "data/incident/#{id}.json"
    end

    def self.upload_path(issue_iid, secret, file_name)
      uploads_path = self.uploads_path(issue_iid)

      File.join(uploads_path, secret, file_name)
    end

    def self.uploads_path(issue_iid)
      File.join('data', 'incident', issue_iid.to_s, '/')
    end

    def self.list_path
      'data/list.json'
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
