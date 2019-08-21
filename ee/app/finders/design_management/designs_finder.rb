# frozen_string_literal: true

module DesignManagement
  class DesignsFinder
    attr_reader :issue, :current_user, :params

    def initialize(issue, current_user, params = {})
      @issue = issue
      @current_user = current_user
      @params = params
    end

    def execute
      unless Ability.allowed?(current_user, :read_design, issue)
        return ::DesignManagement::Design.none
      end

      by_visible_at_version(issue.designs)
    end

    private

    # Returns all designs that existed at a particular design version
    def by_visible_at_version(items)
      items.visible_at_version(params[:visible_at_version])
    end
  end
end
