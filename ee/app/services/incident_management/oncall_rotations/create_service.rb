# frozen_string_literal: true

module IncidentManagement
  module OncallRotations
    class CreateService
      # @param schedule [IncidentManagement::OncallSchedule]
      # @param project [Project]
      # @param user [User]
      # @param params [Hash]
      # @participants participants [Array[Hash]]
      def initialize(schedule, project, user, params, participants)
        @schedule = schedule
        @project = project
        @user = user
        @params = params
        @participants = participants
      end

      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        oncall_rotation = schedule.oncall_rotations.create(params)

        return error_in_create(oncall_rotation) unless oncall_rotation.persisted?

        participants.each do |participant|
          OncallParticipant.create(
            oncall_rotation: oncall_rotation,
            participant: participant[:user],
            color_palette:  participant[:color_palette],
            color_weight: participant[:color_weight]
          )
        end

        success(oncall_rotation)
      end

      private

      attr_reader :schedule, :project, :user, :params, :participants

      def allowed?
        user&.can?(:admin_incident_management_oncall_schedule, project)
      end

      def available?
        Feature.enabled?(:oncall_schedules_mvc, project) &&
          project.feature_available?(:oncall_schedules)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(oncall_rotation)
        ServiceResponse.success(payload: { oncall_rotation: oncall_rotation })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to create an on-call rotation for this project'))
      end

      def error_no_license
        error(_('Your license does not support on-call rotations'))
      end

      def error_in_create(oncall_rotation)
        error(oncall_rotation.errors.full_messages.to_sentence)
      end
    end
  end
end
