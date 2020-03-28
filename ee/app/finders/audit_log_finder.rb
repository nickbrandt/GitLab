# frozen_string_literal: true

class AuditLogFinder
  include CreatedAtFilter
  include FinderMethods

  VALID_ENTITY_TYPES = %w[Project User Group].freeze

  # Instantiates a new finder
  #
  # @param [Hash] params
  # @option params [String] :entity_type
  # @option params [Integer] :entity_id
  # @option params [DateTime] :created_after from created_at date
  # @option params [DateTime] :created_before to created_at date
  # @option params [String] :sort order by field_direction (e.g. created_asc)
  #
  # @return [AuditLogFinder]
  def initialize(params = {})
    @params = params
  end

  # Filters and sorts records according to `params`
  #
  # @return [AuditEvent::ActiveRecord_Relation]
  def execute
    audit_events = AuditEvent.all
    audit_events = by_entity(audit_events)
    audit_events = by_created_at(audit_events)

    sort(audit_events)
  end

  private

  attr_reader :params

  def by_entity(audit_events)
    return audit_events unless valid_entity_type?

    audit_events = audit_events.by_entity_type(params[:entity_type])

    if valid_entity_id?
      audit_events = audit_events.by_entity_id(params[:entity_id])
    end

    audit_events
  end

  def sort(audit_events)
    audit_events.order_by(params[:sort])
  end

  def valid_entity_type?
    VALID_ENTITY_TYPES.include? params[:entity_type]
  end

  def valid_entity_id?
    params[:entity_id].to_i.nonzero?
  end
end
