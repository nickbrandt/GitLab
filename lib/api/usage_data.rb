# frozen_string_literal: true

module API
  class UsageData < Grape::API::Instance
    before { authenticate! }

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_api, default_enabled: true)
      end

      desc 'Track usage data events' do
        detail 'This feature was introduced in GitLab 13.4.'
      end

      params do
        requires :name, type: String, desc: 'The event name it should be tracked'
      end

      post 'increment_unique_users' do
        event_name = params[:name]

        increment_unique_values(event_name, current_user.id)

        status :ok
      end
    end
  end
end
