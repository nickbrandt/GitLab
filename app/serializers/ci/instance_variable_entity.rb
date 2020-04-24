# frozen_string_literal: true

module Ci
  class InstanceVariableEntity < Grape::Entity
    expose :id
    expose :key
    expose :value
    expose :variable_type

    expose :protected?, as: :protected
    expose :masked?, as: :masked
  end
end
