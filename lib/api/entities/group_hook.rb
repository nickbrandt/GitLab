# frozen_string_literal: true

module API
  module Entities
    module GroupHook < Entities::Hook
      expose :group_id
    end
  end
end