# frozen_string_literal: true

class CycleAnalytics::CycleAnalyticsEntity < Grape::Entity
  include RequestAwareEntity

  expose :events, using: CycleAnalytics::EventEntity
  expose :stages, using: CycleAnalytics::StageEntity

  def events
    Gitlab::CycleAnalytics::StageEvents::EVENTS
  end

  def stages
    object
  end
end
