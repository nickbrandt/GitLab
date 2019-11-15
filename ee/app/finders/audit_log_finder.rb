# frozen_string_literal: true

class AuditLogFinder
  include CreatedAtFilter
  VALID_ENTITY_TYPES = %w[Project User Group].freeze

  def initialize(params)
    @params = params
  end

  def execute
    audit_events = AuditEvent.order(id: :desc) # rubocop: disable CodeReuse/ActiveRecord
    audit_events = by_entity(audit_events)
    audit_events = by_created_at(audit_events)
    audit_events = by_id(audit_events)

    audit_events
  end

  private

  attr_reader :params

  def by_entity(audit_events)
    return audit_events unless valid_entity_type?

    audit_events = audit_events.by_entity_type(params[:entity_type])

    if params[:entity_id].present? && params[:entity_id] != '0'
      audit_events = audit_events.by_entity_id(params[:entity_id])
    end

    audit_events
  end

  def by_id(audit_events)
    return audit_events unless params[:id].present?

    audit_events.find_by_id(params[:id])
  end

  def valid_entity_type?
    VALID_ENTITY_TYPES.include? params[:entity_type]
  end
end
