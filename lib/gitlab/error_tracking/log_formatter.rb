# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class LogFormatter
      def self.format!(exception, extra, payload)
        Gitlab::ExceptionLogFormatter.format!(exception, payload)
        append_context_to_log!(payload)
        append_extra_to_log!(extra, payload)
      end

      def self.append_context_to_log!(payload)
        Raven.context.tags.each do |key, value|
          payload["tags.#{key}"] = value
        end

        Raven.context.user.each do |key, value|
          payload["user.#{key}"] = value
        end

        current_context = ::Gitlab::ApplicationContext.current
        payload.merge!(
          'user.username' => current_context['meta.user'],
          'tags.program' => Gitlab.process_name,
          'tags.locale' => I18n.locale,
          'tags.feature_category' => current_context['meta.feature_category']
        )

        payload
      end

      def self.append_extra_to_log!(extra, payload)
        extra = Raven.context.extra.merge(extra).except(:server)

        sidekiq_extra = extra[:sidekiq]
        if sidekiq_extra.is_a?(Hash) && sidekiq_extra.key?('args')
          sidekiq_extra = sidekiq_extra.dup
          sidekiq_extra['args'] = Gitlab::ErrorTracking::Processor::SidekiqProcessor.loggable_arguments(
            value['args'], value['class']
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
