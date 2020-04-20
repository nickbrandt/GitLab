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

      error_message = set_new_parent
      return error(error_message) if error_message.present?

      move!
      success
    end

    private

    def set_new_parent
      return unless new_parent && new_parent_different?

      moving_object.parent = new_parent
      validate_new_parent
    end

    def new_parent_different?
      params[:new_parent_id] != GitlabSchema.id_from_object(moving_object.parent)
    end

    def validate_new_parent
      return unless moving_object.respond_to?(:valid_parent?)
      return if moving_object.valid_parent?

      moving_object.errors[:parent]&.first
    end

    def move!
      moving_object.move_between(before_object, after_object)
      moving_object.save!(touch: false)
    end

    def before_object
      return unless params[:relative_position] == 'before'

      adjacent_reference
    end

    def after_object
      return unless params[:relative_position] == 'after'

      adjacent_reference
    end

    def validate_objects
      return 'Relative position is not valid.' unless valid_relative_position?

      unless supported_type?(moving_object) && supported_type?(adjacent_reference)
        return 'Only epics and epic_issues are supported.'
      end

      return 'You don\'t have permissions to move the objects.' unless authorized?

      if different_epic_parent?
        return "The sibling object's parent must match the #{new_parent ? "new" : "current"} parent epic."
      end
    end

    def valid_relative_position?
      %w(before after).include?(params[:relative_position])
    end

    def different_epic_parent?
      if new_parent
        new_parent != adjacent_reference.parent
      else
        moving_object.parent != adjacent_reference.parent
      end
    end

    def supported_type?(object)
      object.is_a?(EpicIssue) || object.is_a?(Epic)
    end

    def authorized?
      return false unless can?(current_user, :admin_epic, base_epic.group)
      return false unless can?(current_user, :admin_epic, adjacent_reference_group)

      if new_parent
        return false unless can?(current_user, :admin_epic, new_parent.group)
        return false unless moving_object.parent && can?(current_user, :admin_epic, moving_object.parent.group)
      end

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

    def new_parent
      return unless params[:new_parent_id]

      @new_parent ||= find_object(params[:new_parent_id])&.sync
    end

    def find_object(id)
      GitlabSchema.object_from_id(id)
    end
  end
end
