# frozen_string_literal: true
class Groups::Security::VulnerabilitiesController < Groups::Security::ApplicationController
  def index
    @vulnerabilities = group.latest_vulnerabilities.ordered
      .page(params[:page])

    respond_to do |format|
      format.json do
        render json: Vulnerabilities::OccurrenceSerializer
          .new(current_user: @current_user)
          .with_pagination(request, response)
          .represent(@vulnerabilities, preload: true)
      end
    end
  end

  def summary
    respond_to do |format|
      format.json do
        render json: VulnerabilitySummarySerializer.new.represent(group)
      end
    end
  end
end
