# frozen_string_literal: true

module Gitlab
  # Provides routines to identify the current runtime as which the application
  # executes, such as whether it is an application server and which one.
  module Runtime
    class << self
      def name
        matches = []
        matches << :puma if puma?
        matches << :unicorn if unicorn?
        matches << :console if console?
        matches << :sidekiq if sidekiq?

        raise "Ambiguous process match: #{matches}" if matches.size > 1

        matches.first || :unknown
      end

      def puma?
        !!defined?(::Puma)
      end

      # For unicorn, we need to check for actual server instances to avoid false positives.
      def unicorn?
        !!defined?(::Unicorn)
      end

      def sidekiq?
        !!Sidekiq.server?
      end

      def console?
        !!defined?(::Rails::Console)
      end

      def app_server?
        puma? || unicorn?
      end

      def multi_threaded?
        puma? || sidekiq?
      end
    end
  end
end
