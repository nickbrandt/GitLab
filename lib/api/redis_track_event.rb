# frozen_string_literal: true

module API
  class RedisTrackEvent < Grape::API::Instance
    before { authenticate! }

    TRACK_EVENTS_FEATURE = :api_track_redis_events

    resource :redis_track_event do
      desc 'Track event using Redis HLL' do
        detail 'This feature was introduced in GitLab 13.4.'
      end

      params do
        requires :name, type: String, desc: 'The event name it should be tracked'
      end

      post do
        event_name = params[:name]

        redis_track_event(event_name, current_user.id, TRACK_EVENTS_FEATURE)

        status :ok
      end
    end
  end
end
