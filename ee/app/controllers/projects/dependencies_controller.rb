# frozen_string_literal: true

module Projects
  class DependenciesController < Projects::ApplicationController
    before_action :authorize_read_dependencies!
  end
end
