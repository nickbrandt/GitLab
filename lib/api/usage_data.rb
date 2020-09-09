# frozen_string_literal: true

module API
  class UsageData < Grape::API::Instance
    before { authenticate! }

    ALLOWED_ARRAY_SIZE = 10
    ALLOWED_VALUE_SIZE = 36

    helpers do
      def valid_values(values)
        values.size <= ALLOWED_ARRAY_SIZE && values.all? { |value| value.is_a?(String) && value.size <= ALLOWED_VALUE_SIZE }
      end
    end

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_api, default_enabled: true)
      end

      desc 'Track usage data events' do
        detail 'This feature was introduced in GitLab 13.4.'
      end

      params do
        requires :name, type: String, desc: 'The event name it should be tracked'
        requires :values, type: Array, desc: 'The values counted'
      end

      post 'increment_unique_values' do
        event_name = params[:name]
        values = params[:values]

        unless valid_values(values)
          render_api_error!('values needs to be an array of maxim 10 elements of strings of size maximum 36', 400)
        end

        increment_unique_values(event_name, values)

        status :ok
      end
    end
  end
end
