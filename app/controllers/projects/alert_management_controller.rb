# frozen_string_literal: true

class Projects::AlertManagementController < Projects::ApplicationController
  def index
    respond_to do |format|
      format.html
      format.json do
        render_index_json
      end


    end
  end

  private

  def render_index_json
    result = []

    render json: {
      alerts: result
    }
  end
end
