# frozen_string_literal: true

module StatusPage
  module Storage
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
