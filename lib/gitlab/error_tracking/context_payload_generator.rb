# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class ContextPayloadGenerator
      def self.generate(exception, extra = {})
        new.generate(exception, extra)
      end

      def generate(exception, extra = {})
        payload = {}

        append_extra!(payload, exception, extra)
        append_tags!(payload)
        append_user!(payload)

        payload
      end

      private

      def append_extra!(payload, exception, extra)
        inline_extra = exception.try(:sentry_extra_data)
        if inline_extra.present? && inline_extra.is_a?(Hash)
          extra = extra.merge(inline_extra)
        end

        payload[:extra] = sanitize_request_parameters(extra)
      end

      def sanitize_request_parameters(parameters)
        filter = ActiveSupport::ParameterFilter.new(::Rails.application.config.filter_parameters)
        filter.filter(parameters)
      end

      def append_tags!(payload)
        payload[:tags] = {}
        payload[:tags]
          .merge!(extra_tags_from_env)
          .merge!(
            program: Gitlab.process_name,
            locale: I18n.locale,
            feature_category: current_context['meta.feature_category'],
            Labkit::Correlation::CorrelationId::LOG_KEY.to_sym => Labkit::Correlation::CorrelationId.current_id
          )
      end

      def append_user!(payload)
        payload[:user] = {
          username: current_context['meta.user']
        }
      end

      # Static tags that are set on application start
      def extra_tags_from_env
        Gitlab::Json.parse(ENV.fetch('GITLAB_SENTRY_EXTRA_TAGS', '{}')).to_hash
      rescue => e
        Gitlab::AppLogger.debug("GITLAB_SENTRY_EXTRA_TAGS could not be parsed as JSON: #{e.class.name}: #{e.message}")

        {}
      end

      def current_context
        # In case Gitlab::ErrorTracking is used when the app starts
        return {} unless defined?(::Gitlab::ApplicationContext)

        ::Gitlab::ApplicationContext.current.to_h
      end
    end
  end
end
