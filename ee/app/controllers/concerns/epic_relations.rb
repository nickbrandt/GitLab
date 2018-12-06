# frozen_string_literal: true

module EpicRelations
  extend ActiveSupport::Concern
  include IssuableLinks

  included do
    skip_before_action :authorize_destroy_issuable!
    skip_before_action :authorize_create_epic!
    skip_before_action :authorize_update_issuable!

    before_action :authorize_admin_epic!, only: [:create, :destroy, :update]
  end

  def authorize_admin_epic!
    render_403 unless can?(current_user, :admin_epic, epic)
  end
end
