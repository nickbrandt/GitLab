# frozen_string_literal: true

module IssuableLinks
  class ListService
    include Gitlab::Routing

    attr_reader :issuable, :current_user

    def initialize(issuable, user)
      @issuable, @current_user = issuable, user
    end

    def execute
      child_issuables.map do |referenced_object|
        to_hash(referenced_object)
      end
    end

    private

    def preload_for_collection
      [{ project: :namespace }, :assignees]
    end

    def relation_path(object)
      raise NotImplementedError
    end

    def reference(object)
      object.to_reference(issuable.project)
    end

    def issuable_path(object)
      project_issue_path(object.project, object.iid)
    end

    # rubocop: disable CodeReuse/Serializer
    def to_hash(object)
      {
        id: object.id,
        confidential: object.confidential,
        title: object.title,
        assignees: UserSerializer.new.represent(object.assignees),
        state: object.state,
        milestone: MilestoneSerializer.new.represent(object.milestone),
        weight: object.weight,
        reference: reference(object),
        path: issuable_path(object),
        relation_path: relation_path(object),
        due_date: object.due_date,
        created_at: object.created_at,
        closed_at: object.closed_at
      }
    end
    # rubocop: enable CodeReuse/Serializer
  end
end
