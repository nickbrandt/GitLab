# frozen_string_literal: true

class Groups::AuditEventsController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :check_audit_events_available!

  layout 'group_settings'

  def index
    @events = AuditLogFinder.new(entity_type: group.class.name, entity_id: group.id).execute.page(params[:page])
  end
end
