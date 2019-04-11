# frozen_string_literal: true

module EpicRelations
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include IssuableLinks

  included do
    before_action :check_epics_available!
    before_action :authorize_read_epic!, only: :index
    before_action :authorize_admin_epic!, only: [:create, :destroy, :update]
  end

  def authorize_read_epic!
    render_404 unless can?(current_user, :read_epic, epic)
  end

  def authorize_admin_epic!
    render_403 unless can?(current_user, :admin_epic, epic)
  end

  def epic
    strong_memoize(:epic) do
      group.epics.find_by_iid(params[:epic_id])
    end
  end
end
