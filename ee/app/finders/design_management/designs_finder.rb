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

      items = issue.designs
      items = by_visible_at_version(items)
      items
    end

    private

    # Returns all designs that existed at a particular design version
    def by_visible_at_version(items)
      return items unless params[:visible_at_version]

      items.visible_at_version(params[:visible_at_version])
    end
  end
end
