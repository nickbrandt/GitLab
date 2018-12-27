# frozen_string_literal: true

module EE
  module Audit
    module Changes
      def audit_changes(column, options = {})
        column = options[:column] || column
        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @target_model = options[:target_model]
        @model = options[:model]
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        return unless changed?(column)

        audit_event(parse_options(column, options))
      end

      protected

      def target_model
        @target_model || model # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def model
        @model
      end

      private

      def changed?(column)
        model.previous_changes.has_key?(column)
      end

      def changes(column)
        model.previous_changes[column]
      end

      def parse_options(column, options)
        options.tap do |options_hash|
          options_hash[:column] = column
          options_hash[:action] = :update

          unless options[:skip_changes]
            options_hash[:from] = changes(column).first
            options_hash[:to] = changes(column).last
          end
        end
      end

      def audit_event(options)
        ::AuditEventService.new(@current_user, target_model, options) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          .for_changes.security_event
      end
    end
  end
end
