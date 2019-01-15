# frozen_string_literal: true

class Groups::EpicLinksController < Groups::EpicsController
  include EpicRelations

  before_action :check_nested_support!

  def destroy
    result = ::Epics::UpdateService.new(group, current_user, { parent: nil }).execute(child_epic)

    render json: { issuables: issuables }, status: result[:http_status]
  end

  private

  def create_service
    EpicLinks::CreateService.new(epic, current_user, create_params)
  end

  def list_service
    EpicLinks::ListService.new(epic, current_user)
  end

  def child_epic
    @child_epic ||= Epic.find(params[:id])
  end

  def check_nested_support!
    render_404 unless Epic.supports_nested_objects?
  end
end
