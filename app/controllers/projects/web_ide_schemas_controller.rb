# frozen_string_literal: true

class Projects::WebIdeTerminalsController < Projects::ApplicationController
  before_action :authenticate_user!

  def check_config
    return respond_422 unless branch_sha

    if project.feature_enabled?(:ide_schema_config)
      result = ::Ci::WebIdeConfigService.new(project, current_user, sha: branch_sha).load_schemas_config

    if result[:status] == :success
      head :ok
      render json: result
    else
      head :ok
      render json: {}
    end
  end

  def show
    render_terminal(build)
  end
end
