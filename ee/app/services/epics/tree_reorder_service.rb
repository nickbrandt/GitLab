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
      klass = case moving_object
              when EpicIssue
                EpicIssues::UpdateService
              when Epic
                EpicLinks::UpdateService
              end

      return error('Only epics and epic_issues are supported.') unless klass

      error_message = validate_objects

      return error(error_message) if error_message.present?

      klass.new(moving_object, current_user, moving_params).execute
    end

    private

    def moving_params
      key = case params[:relative_position].to_sym
            when :after
              :move_after_id
            when :before
              :move_before_id
            end

      {}.tap { |p| p[key] = adjacent_reference.id }
    end

    # for now we support only ordering within the same type
    # Follow-up issue: https://gitlab.com/gitlab-org/gitlab/issues/13633
    def validate_objects
      return 'You don\'t have permissions to move the objects.' unless authorized?
      return 'Provided objects are not the same type.' if moving_object.class != adjacent_reference.class
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
