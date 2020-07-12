# frozen_string_literal: true

module Analytics
  class GroupValueStreamEntity < Grape::Entity
    expose :name
    expose :id
  end
end
