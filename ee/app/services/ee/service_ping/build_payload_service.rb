# frozen_string_literal: true

module EE
  module ServicePing
    module BuildPayloadService
      extend ::Gitlab::Utils::Override

      STANDARD_CATEGORY = 'Standard'
      SUBSCRIPTION_CATEGORY = 'Subscription'
      OPTIONAL_CATEGORY = 'Optional'
      OPERATIONAL_CATEGORY = 'Operational'

      override :execute
      def execute
        return super unless ::License.current.present?

        filtered_usage_data(super)
      end

      private

      override :product_intelligence_enabled?
      def product_intelligence_enabled?
        ::License.current&.usage_ping? || super
      end

      def filtered_usage_data(payload = raw_payload, parents = [])
        payload.keep_if do |label, node|
          if leaf?(node)
            permitted_categories.include?(metric_category(label, parents))
          else
            filtered_usage_data(node, parents.dup << label)
          end
        end
      end

      def permitted_categories
        @permitted_categories ||= collect_permitted_categories
      end

      def collect_permitted_categories
        categories = [STANDARD_CATEGORY, SUBSCRIPTION_CATEGORY]
        categories << OPTIONAL_CATEGORY if ::Gitlab::CurrentSettings.usage_ping_enabled?
        categories << OPERATIONAL_CATEGORY if ::License.current.usage_ping?
        categories
      end

      def metric_category(key, parent_keys)
        key_path = parent_keys.dup.append(key).join('.')
        metric_definitions[key_path]&.attributes&.fetch(:data_category, OPTIONAL_CATEGORY)
      end

      def metric_definitions
        @metric_definitions ||= ::Gitlab::Usage::MetricDefinition.definitions
      end

      def leaf?(node)
        !node.is_a?(Hash)
      end
    end
  end
end
