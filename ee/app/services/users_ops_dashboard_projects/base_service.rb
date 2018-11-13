# frozen_string_literal: true

module UsersOpsDashboardProjects
  class BaseService
    attr_reader :user

    def initialize(user)
      @user = user
    end
  end
end
