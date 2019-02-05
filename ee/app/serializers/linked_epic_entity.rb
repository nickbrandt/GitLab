# frozen_string_literal: true

class LinkedEpicEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :title, :state

  expose :reference do |epic|
    epic.to_reference(request.issuable.group)
  end

  expose :path do |epic|
    group_epic_path(epic.group, epic)
  end

  expose :relation_path do |epic|
    group_epic_link_path(epic.group, request.issuable.iid, epic.id)
  end
end
