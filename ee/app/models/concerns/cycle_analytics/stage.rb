# frozen_string_literal: true

module CycleAnalytics
  module Stage
    extend ActiveSupport::Concern
    include RelativePositioning

    included do
      belongs_to :start_event_label, class_name: 'Label'
      belongs_to :end_event_label, class_name: 'Label'

      validates :name, presence: true
      validates :start_event_label, presence: true, if: :start_event_is_label_based?
      validates :end_event_label, presence: true, if: :end_event_is_label_based?
      validates :start_event_label, absence: true, unless: :start_event_is_label_based?
      validates :end_event_label, absence: true, unless: :end_event_is_label_based?
      validate :validate_stage_event_pairs

      enum start_event_identifier: Gitlab::CycleAnalytics::StageEvents.to_enum, _prefix: :start_event_identifier
      enum end_event_identifier: Gitlab::CycleAnalytics::StageEvents.to_enum, _prefix: :end_event_identifier

      scope :ordered, -> { order(:relative_position) }
    end

    def parent
      raise NotImplementedError
    end

    def start_event
      Gitlab::CycleAnalytics::StageEvents[start_event_identifier].new({ label: start_event_label })
    end

    def end_event
      Gitlab::CycleAnalytics::StageEvents[end_event_identifier].new({ label: end_event_label })
    end

    def custom_stage?
      custom
    end

    def default_stage?
      !custom
    end

    def model_to_query
      start_event.object_type
    end

    private

    def validate_stage_event_pairs
      return if start_event_identifier.nil? || end_event_identifier.nil?

      unless Gitlab::CycleAnalytics::StageEvents::PAIRING_RULES.fetch(start_event.class, []).include?(end_event.class)
        errors.add(:end_event, :not_allowed_for_the_given_start_event)
      end
    end

    def start_event_is_label_based?
      start_event.class.label_based?
    end

    def end_event_is_label_based?
      end_event.class.label_based?
    end

  end
end
