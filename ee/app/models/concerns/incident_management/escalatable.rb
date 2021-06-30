# frozen_string_literal: true

module IncidentManagement
  module Escalatable
    extend ActiveSupport::Concern

    STATUSES = {
      triggered: 0,
      acknowledged: 1,
      resolved: 2,
      ignored: 3
    }.freeze

    STATUS_DESCRIPTIONS = {
      triggered: 'Investigation has not started',
      acknowledged: 'Someone is actively investigating the problem',
      resolved: 'The problem has been addressed',
      ignored: 'No action will be taken'
    }.freeze

    included do
      state_machine :status, initial: :triggered do
        state :triggered, value: STATUSES[:triggered]

        state :acknowledged, value: STATUSES[:acknowledged]

        state :resolved, value: STATUSES[:resolved] do
          validates :ended_at, presence: true
        end

        state :ignored, value: STATUSES[:ignored]

        state :triggered, :acknowledged, :ignored do
          validates :ended_at, absence: true
        end

        event :trigger do
          transition any => :triggered
        end

        event :acknowledge do
          transition any => :acknowledged
        end

        event :resolve do
          transition any => :resolved
        end

        event :ignore do
          transition any => :ignored
        end

        before_transition to: [:triggered, :acknowledged, :ignored] do |escalatable, _transition|
          escalatable.ended_at = nil
        end

        before_transition to: :resolved do |escalatable, transition|
          ended_at = transition.args.first
          escalatable.ended_at = ended_at || Time.current
        end
      end

      def self.state_machine_statuses
        @state_machine_statuses ||= state_machines[:status].states.to_h { |s| [s.name, s.value] }
      end
      private_class_method :state_machine_statuses

      def self.status_value(name)
        state_machine_statuses[name]
      end

      def self.status_name(raw_status)
        state_machine_statuses.key(raw_status)
      end

      def self.counts_by_status
        group(:status).count.transform_keys { |k| status_name(k) }
      end

      def self.status_names
        @status_names ||= state_machine_statuses.keys
      end

      def self.open_statuses
        [:triggered, :acknowledged]
      end

      def self.open_status?(status)
        open_statuses.include?(status)
      end

      def open?
        self.class.open_status?(status_name)
      end

      def status_event_for(status)
        self.class.state_machines[:status].events.transitions_for(self, to: status.to_s.to_sym).first&.event
      end

      def change_status_to(new_status)
        event = status_event_for(new_status)
        event && fire_status_event(event)
      end
    end
  end
end
