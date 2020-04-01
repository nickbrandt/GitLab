# frozen_string_literal: true

module Ci
  class MinutesNotificationService
    include Gitlab::Allowable

    attr_reader :namespace

    def self.call(*args)
      new(*args).call
    end

    def initialize(current_user, project, namespace)
      @current_user = current_user
      @project = project
      @namespace = namespace
    end

    def call
      calculate

      self
    end

    def show_notification?
      can_see_limit_reached? && namespace.shared_runners_remaining_minutes_below_threshold?
    end

    def show_alert?
      can_see_limit_reached? && below_threshold?
    end

    def scope
      level.full_path
    end

    private

    attr_reader :project,
                :can_see_status,
                :has_limit,
                :current_user,
                :level

    def calculate
      if at_namespace_level?
        calculate_from_namespace_level
      else
        calculate_from_project_level
      end

      @has_limit = level.shared_runners_minutes_limit_enabled?
    end

    def at_namespace_level?
      namespace && !project
    end

    def calculate_from_namespace_level
      @level = namespace
      @can_see_status = true
    end

    def calculate_from_project_level
      @level = project
      @namespace = project.shared_runners_limit_namespace
      @can_see_status = can?(current_user, :create_pipeline, project)
    end

    def can_see_limit_reached?
      has_limit && can_see_status
    end

    def below_threshold?
      namespace.shared_runners_minutes_used? || namespace.shared_runners_remaining_minutes_below_threshold?
    end
  end
end
