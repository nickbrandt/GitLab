# frozen_string_literal: true

module Gitlab
  module Audit
    class Auditor
      # Record audit events
      #
      # @param [Hash] context
      # @option context [String] :name the operation name to be audited, used for error tracking
      # @option context [User] :author the user who authors the change
      # @option context [User, Project, Group] :scope the scope which audit event belongs to
      # @option context [Object] :target the target object being audited
      # @option context [String] :message the message describing the action
      #
      # @example Using block (useful when events are emitted deep in the call stack)
      #   i.e. multiple audit events
      #
      #   audit_context = {
      #     name: 'merge_approval_rule_updated',
      #     author: current_user,
      #     scope: project_alpha,
      #     target: merge_approval_rule,
      #     message: 'a user has attempted to update an approval rule'
      #   }
      #
      #   # in the initiating service
      #   Gitlab::Audit::Auditor.audit(audit_context) do
      #     service.execute
      #   end
      #
      #   # in the model
      #   Auditable.push_audit_event('an approver has been added')
      #   Auditable.push_audit_event('an approval group has been removed')
      #
      # @example Using standard method call
      #   i.e. single audit event
      #
      #   merge_approval_rule.save
      #   Gitlab::Audit::Auditor.audit(audit_context)
      #
      # @return result of block execution
      def self.audit(context, &block)
        auditor = new(context)

        if block
          auditor.multiple_audit(&block)
        else
          auditor.single_audit
        end
      end

      def initialize(context = {})
        @context = context

        @name = @context.fetch(:name, 'audit_operation')
        @author = @context.fetch(:author)
        @scope = @context.fetch(:scope)
        @target = @context.fetch(:target)
        @message = @context.fetch(:message, '')
      end

      def multiple_audit
        ::Gitlab::Audit::EventQueue.begin!

        return_value = yield

        ::Gitlab::Audit::EventQueue.current
          .map { |message| build_event(message) }
          .then { |events| record(events) }

        return_value
      ensure
        ::Gitlab::Audit::EventQueue.end!
      end

      def single_audit
        events = [build_event(@message)]
        record(events)
      end

      def record(events)
        log_to_database(events)
        log_to_file(events)
      end

      def build_event(message)
        AuditEvents::BuildService.new(
          author: @author,
          scope: @scope,
          target: @target,
          message: message
        ).execute
      end

      def log_to_database(events)
        AuditEvent.bulk_insert!(events)
      rescue ActiveRecord::RecordInvalid => error
        ::Gitlab::ErrorTracking.track_exception(error, audit_operation: @name)
      end

      def log_to_file(events)
        file_logger = ::Gitlab::AuditJsonLogger.build

        events.each { |event| file_logger.info(event.as_json) }
      end
    end
  end
end
