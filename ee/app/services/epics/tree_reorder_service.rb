# frozen_string_literal: true

module Epics
  class TreeReorderService < BaseService
    attr_reader :current_user, :moving_object, :params

    def initialize(current_user, moving_object_id, params)
      @current_user = current_user
      @params = params
      @moving_object = find_object(moving_object_id)&.sync
    end

    def execute
      error_message = validate_objects

      return error(error_message) if error_message.present?

      move!
      success
    end

    private

    def move!
      moving_object.move_between(before_object, after_object)
      moving_object.save!(touch: false)
    end

    def before_object
      return unless params[:relative_position].to_sym == :before

      adjacent_reference
    end

    def after_object
      return unless params[:relative_position].to_sym == :after

      adjacent_reference
    end

    def validate_objects
      unless moving_object.is_a?(EpicIssue) || moving_object.is_a?(Epic)
        return 'Only epics and epic_issues are supported.'
      end

      return 'You don\'t have permissions to move the objects.' unless authorized?
    end

    def authorized?
      return false unless can?(current_user, :admin_epic, base_epic.group)
      return false unless can?(current_user, :admin_epic, adjacent_reference_group)

      true
    end

    def adjacent_reference_group
      case adjacent_reference
      when EpicIssue
        adjacent_reference&.epic&.group
      when Epic
        adjacent_reference&.group
      else
        nil
      end
    end

    def base_epic
      @base_epic ||= find_object(params[:base_epic_id])&.sync
    end

    def adjacent_reference
      @adjacent_reference ||= find_object(params[:adjacent_reference_id])&.sync
    end

    def find_object(id)
      GitlabSchema.object_from_id(id)
    end
  end
end
