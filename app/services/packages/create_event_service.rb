# frozen_string_literal: true

module Packages
  class CreateEventService < BaseService
    def execute
      if Feature.enabled?(:collect_package_events_redis) && redis_event_name
        if guest?
          ::Gitlab::UsageDataCounters::GuestPackageEventCounter.count(redis_event_name)
        else
          ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(current_user.id, redis_event_name)
        end
      end

      if Feature.enabled?(:collect_package_events) && Gitlab::Database.read_write?
        ::Packages::Event.create!(
          event_type: event_name,
          originator: current_user.try(:id),
          originator_type: originator_type,
          event_scope: event_scope,
          container_repository_id: container_repository_id
        )
      end
    end

    private

    def redis_event_name
      @redis_event_name ||= ::Packages::Event.allowed_event_name(event_scope, event_name, originator_type)
    end

    def event_scope
      @event_scope ||= scope.is_a?(::Packages::Package) ? scope.package_type : scope
    end

    def scope
      params[:scope]
    end

    def event_name
      params[:event_name]
    end

    def container_repository_id
      params[:container_repository_id]
    end

    def originator_type
      case current_user
      when User
        :user
      when DeployToken
        :deploy_token
      when :worker
        :worker
      else
        :guest
      end
    end

    def guest?
      originator_type == :guest
    end

    def worker?
      originator_type == :worker
    end
  end
end
