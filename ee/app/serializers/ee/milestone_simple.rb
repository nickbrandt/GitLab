# frozen_string_literal: true

module EE
  class MilestoneSimple < Grape::Entity
    expose :id
    expose :title
  end
end
