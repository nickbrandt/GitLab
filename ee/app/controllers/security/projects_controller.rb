# frozen_string_literal: true

module Security
  class ProjectsController < ::Security::ApplicationController
    def index
      head :ok
    end

    def create
      head :ok
    end

    def destroy
      head :ok
    end
  end
end
