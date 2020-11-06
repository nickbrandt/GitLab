# frozen_string_literal: true

class IssuableSidebarTodoEntity < Grape::Entity
  include Gitlab::Routing

  expose :id
end
