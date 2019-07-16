# frozen_string_literal: true

class CycleAnalytics::EventEntity < Grape::Entity
  expose :name
  expose :identifier
  expose :type 
  expose :can_be_start_event
  expose :allowed_end_events

  private

  def type
    object.label_based? ? 'label' : 'simple'
  end

  def can_be_start_event
    Gitlab::CycleAnalytics::StageEvents::PAIRING_RULES.has_key?(object)
  end

  def allowed_end_events
    Gitlab::CycleAnalytics::StageEvents::PAIRING_RULES.fetch(object , []).map(&:identifier)
  end

  def name
    s_("CycleAnalyticsEvent|#{object.identifier}")
  end
end
