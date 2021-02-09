# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class LogFormatter
      def self.format!(payload, exception, context_payload)
        Gitlab::ExceptionLogFormatter.format!(exception, payload)
        append_user_to_log!(payload, context_payload)
        append_tags_to_log!(payload, context_payload)
        append_extra_to_log!(payload, context_payload)
      end

      def self.append_user_to_log!(payload, context_payload)
        user_context = Raven.context.user.merge(context_payload[:user])
        user_context.each do |key, value|
          payload["user.#{key}"] = value
        end
      end

      def self.append_tags_to_log!(payload, context_payload)
        tags_context = Raven.context.tags.merge(context_payload[:tags])
        tags_context.each do |key, value|
          payload["tags.#{key}"] = value
        end
      end

      def self.append_extra_to_log!(payload, context_payload)
        extra = Raven.context.extra.merge(context_payload[:extra])
        extra = extra.except(:server)

        sidekiq_extra = extra[:sidekiq]
        if sidekiq_extra.is_a?(Hash) && sidekiq_extra.key?('args')
          sidekiq_extra = sidekiq_extra.dup
          sidekiq_extra['args'] = Gitlab::ErrorTracking::Processor::SidekiqProcessor.loggable_arguments(
            sidekiq_extra['args'], sidekiq_extra['class']
          )
        end

        extra[:sidekiq] = sidekiq_extra if sidekiq_extra

        extra.each do |key, value|
          payload["extra.#{key}"] = value
        end

        payload
      end
    end
  end
end
