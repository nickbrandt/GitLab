# frozen_string_literal: true

module API
  module Internal
    class UsageData < Grape::API::Instance
      before { authenticate_by_gitlab_shell_token! }

      namespace 'internal' do
        namespace 'usage_data' do
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

            increment_unique_events(event_name, values)

            status :ok
          end
        end
      end
    end
  end
end
