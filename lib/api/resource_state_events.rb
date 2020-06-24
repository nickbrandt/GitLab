# frozen_string_literal: true

module API
  class ResourceStateEvents < Grape::API::Instance
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    [Issue, MergeRequest].each do |eventable_type|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{eventable_type.to_s.downcase} resource state events" do
          success Entities::ResourceStateEvent
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
          use :pagination
        end

        get ":id/#{eventables_str}/:eventable_id/resource_state_events" do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          events = ResourceStateEventFinder.new(current_user, eventable).execute

          present paginate(events), with: Entities::ResourceStateEvent
        end

        desc "Get a single #{eventable_type.to_s.downcase} resource state event" do
          success Entities::ResourceStateEvent
        end
        params do
          requires :event_id, type: String, desc: 'The ID of a resource state event'
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
        end
        get ":id/#{eventables_str}/:eventable_id/resource_state_events/:event_id" do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          not_found!('ResourceStateEvent') unless ResourceStateEventFinder.new(current_user, eventable).can_read_eventable?

          event = eventable.resource_state_events.find(params[:event_id])

          present event, with: Entities::ResourceStateEvent
        end
      end
    end
  end
end
