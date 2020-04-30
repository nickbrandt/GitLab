# frozen_string_literal: true

module Gitlab
  module Json
    class << self
      def parse(string, *args, **named_args)
        legacy_mode = legacy_mode_enabled?(named_args.delete(:legacy_mode))
        data = adapter.parse(string, *args, **named_args)

        raise parser_error if legacy_mode && [String, TrueClass, FalseClass].any? { |type| data.is_a?(type) }

        data
      end

      def parse!(*args)
        adapter.parse!(*args)
      end

      def dump(*args)
        adapter.dump(*args)
      end

      def generate(*args)
        adapter.generate(*args)
      end

      def pretty_generate(*args)
        adapter.pretty_generate(*args)
      end

      private

      def adapter
        ::JSON
      end

      def parser_error
        ::JSON::ParserError
      end

      def legacy_mode_enabled?(arg_value)
        # This will change to the following once the `json` gem is upgraded:
        # arg_value.nil? ? true : arg_value

        true
      end
    end
  end
end
