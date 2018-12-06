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

    def relation_path(object)
      raise NotImplementedError
    end

    def reference(object)
      object.to_reference(issuable.project)
    end

    def issuable_path(object)
      project_issue_path(object.project, object.iid)
    end

    def to_hash(object)
      {
        id: object.id,
        title: object.title,
        state: object.state,
        reference: reference(object),
        path: issuable_path(object),
        relation_path: relation_path(object)
      }
    end
  end
end
